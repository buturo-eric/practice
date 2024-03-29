import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testt/models/question_model.dart';
import 'package:testt/pages/results.dart';
import 'package:testt/services/database.dart';
import 'package:testt/quiz_play_widgets.dart';
import 'package:uuid/uuid.dart';

class QuizPlay extends StatefulWidget {
  final String quizId;

  QuizPlay(this.quizId);

  @override
  _QuizPlayState createState() => _QuizPlayState();
}

class _QuizPlayState extends State<QuizPlay> {
  late QuerySnapshot questionSnaphot;
  late DatabaseService databaseService; // Declare the database service

  bool isLoading = true;

  static int _correct = 0;
  static int _incorrect = 0;
  static int _notAttempted = 0;
  static int total = 0;

  /// Stream
  static late StreamController<List<int>> infoStreamController;
  static late Stream<List<int>> infoStream;

  @override
  void initState() {
    super.initState();
    databaseService = DatabaseService(uid: Uuid().v4());
    infoStream = Stream<List<int>>.periodic(Duration(milliseconds: 100), (x) {
      print("this is x $x");
      return [_correct, _incorrect];
    });

    // Fetch question data using the quiz ID
    databaseService.getQuestionData(widget.quizId).then((value) {
      questionSnaphot = value;
      _notAttempted = questionSnaphot.docs.length;
      _correct = 0;
      _incorrect = 0;
      isLoading = false;
      total = questionSnaphot.docs.length;
      setState(() {});
      print("init don $total ${widget.quizId} ");
    });
  }

  QuestionModel getQuestionModelFromDatasnapshot(
      DocumentSnapshot questionSnapshot) {
    QuestionModel questionModel = QuestionModel();

    var data = questionSnapshot.data() as Map<String, dynamic>?;

    if (data != null) {
      questionModel.question = (data["question"] as String?)!;

      // Check if question is not null before processing
      if (questionModel.question != null) {
        List<String> options = [
          data["option1"],
          data["option2"],
          data["option3"],
          data["option4"],
        ];
        options.shuffle();

        questionModel.option1 = options[0];
        questionModel.option2 = options[1];
        questionModel.option3 = options[2];
        questionModel.option4 = options[3];
        questionModel.correctOption = data["option1"];
        questionModel.answered = false;

        print(questionModel.correctOption.toLowerCase());
      }
    }

    return questionModel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Container(
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Container(
                child: Column(
                  children: [
                    InfoHeader(
                      length: questionSnaphot.docs.length,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    // ignore: unnecessary_null_comparison
                    questionSnaphot.docs == null
                        ? Container(
                            child: Center(
                              child: Text("No Data"),
                            ),
                          )
                        : ListView.builder(
                            itemCount: questionSnaphot.docs.length,
                            shrinkWrap: true,
                            physics: ClampingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return QuizPlayTile(
                                questionModel: getQuestionModelFromDatasnapshot(
                                  questionSnaphot.docs[index],
                                ),
                                index: index,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Results(
                correct: _correct,
                incorrect: _incorrect,
                total: total,
                quizId: widget.quizId, // Pass the quiz ID to Results page
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        shape: CircleBorder(),
      ),
    );
  }
}

class InfoHeader extends StatefulWidget {
  final int length;

  InfoHeader({required this.length});

  @override
  _InfoHeaderState createState() => _InfoHeaderState();
}

class _InfoHeaderState extends State<InfoHeader> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _QuizPlayState.infoStream,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? Container(
                  height: 40,
                  margin: EdgeInsets.only(left: 14),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: <Widget>[
                      NoOfQuestionTile(
                        text: "Total",
                        number: widget.length,
                      ),
                      NoOfQuestionTile(
                        text: "Correct",
                        number: _QuizPlayState._correct,
                      ),
                      NoOfQuestionTile(
                        text: "Incorrect",
                        number: _QuizPlayState._incorrect,
                      ),
                      NoOfQuestionTile(
                        text: "NotAttempted",
                        number: _QuizPlayState._notAttempted,
                      ),
                    ],
                  ),
                )
              : Container();
        });
  }
}

class QuizPlayTile extends StatefulWidget {
  final QuestionModel questionModel;
  final int index;

  QuizPlayTile({required this.questionModel, required this.index});

  @override
  _QuizPlayTileState createState() => _QuizPlayTileState();
}

class _QuizPlayTileState extends State<QuizPlayTile> {
  String optionSelected = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Q${widget.index + 1} ${widget.questionModel.question}",
              style:
                  TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.8)),
            ),
          ),
          SizedBox(
            height: 12,
          ),
          GestureDetector(
            onTap: () {
              if (!widget.questionModel.answered) {
                if (widget.questionModel.option1 ==
                    widget.questionModel.correctOption) {
                  setState(() {
                    optionSelected = widget.questionModel.option1;
                    widget.questionModel.answered = true;
                    _QuizPlayState._correct = _QuizPlayState._correct + 1;
                  });
                } else {
                  setState(() {
                    optionSelected = widget.questionModel.option1;
                    widget.questionModel.answered = true;
                    _QuizPlayState._incorrect = _QuizPlayState._incorrect + 1;
                  });
                }
                setState(() {
                  _QuizPlayState._notAttempted =
                      _QuizPlayState._notAttempted - 1;
                });
              }
            },
            child: OptionTile(
              option: "A",
              description: "${widget.questionModel.option1}",
              correctAnswer: widget.questionModel.correctOption,
              optionSelected: optionSelected,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          GestureDetector(
            onTap: () {
              if (!widget.questionModel.answered) {
                if (widget.questionModel.option2 ==
                    widget.questionModel.correctOption) {
                  setState(() {
                    optionSelected = widget.questionModel.option2;
                    widget.questionModel.answered = true;
                    _QuizPlayState._correct = _QuizPlayState._correct + 1;
                  });
                } else {
                  setState(() {
                    optionSelected = widget.questionModel.option2;
                    widget.questionModel.answered = true;
                    _QuizPlayState._incorrect = _QuizPlayState._incorrect + 1;
                  });
                }
                setState(() {
                  _QuizPlayState._notAttempted =
                      _QuizPlayState._notAttempted - 1;
                });
              }
            },
            child: OptionTile(
              option: "B",
              description: "${widget.questionModel.option2}",
              correctAnswer: widget.questionModel.correctOption,
              optionSelected: optionSelected,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          GestureDetector(
            onTap: () {
              if (!widget.questionModel.answered) {
                if (widget.questionModel.option3 ==
                    widget.questionModel.correctOption) {
                  setState(() {
                    optionSelected = widget.questionModel.option3;
                    widget.questionModel.answered = true;
                    _QuizPlayState._correct = _QuizPlayState._correct + 1;
                  });
                } else {
                  setState(() {
                    optionSelected = widget.questionModel.option3;
                    widget.questionModel.answered = true;
                    _QuizPlayState._incorrect = _QuizPlayState._incorrect + 1;
                  });
                }
                setState(() {
                  _QuizPlayState._notAttempted =
                      _QuizPlayState._notAttempted - 1;
                });
              }
            },
            child: OptionTile(
              option: "C",
              description: "${widget.questionModel.option3}",
              correctAnswer: widget.questionModel.correctOption,
              optionSelected: optionSelected,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          GestureDetector(
            onTap: () {
              if (!widget.questionModel.answered) {
                if (widget.questionModel.option4 ==
                    widget.questionModel.correctOption) {
                  setState(() {
                    optionSelected = widget.questionModel.option4;
                    widget.questionModel.answered = true;
                    _QuizPlayState._correct = _QuizPlayState._correct + 1;
                  });
                } else {
                  setState(() {
                    optionSelected = widget.questionModel.option4;
                    widget.questionModel.answered = true;
                    _QuizPlayState._incorrect = _QuizPlayState._incorrect + 1;
                  });
                }
                setState(() {
                  _QuizPlayState._notAttempted =
                      _QuizPlayState._notAttempted - 1;
                });
              }
            },
            child: OptionTile(
              option: "D",
              description: "${widget.questionModel.option4}",
              correctAnswer: widget.questionModel.correctOption,
              optionSelected: optionSelected,
            ),
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}