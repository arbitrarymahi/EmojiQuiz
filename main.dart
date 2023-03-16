import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Game',
      home: BlocProvider(
        create: (context) => QuizBloc(),
        child: QuizScreen(),
      ),
    );
  }
}

class QuizScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Game'),
      ),
      body: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          if (state is QuizLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Question(question: state.quiz.questions[state.currentQuestionIndex]),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.quiz.questions[state.currentQuestionIndex].answers.length,
                    itemBuilder: (context, index) {
                      return Answer(
                        answer: state.quiz.questions[state.currentQuestionIndex].answers[index],
                        onTap: () {
                          BlocProvider.of<QuizBloc>(context).add(AnswerSelected(answerIndex: index));
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is QuizFinished) {
            return Stack(
              children: [
                Center(
                  child: Text('Game Over! Your score is ${state.score}'),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () {
                      BlocProvider.of<QuizBloc>(context).add(StartQuiz());
                    },
                    child: Text('Start New Game'),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class Question {
  final String question;
  final List<String> answers;
  final int correctAnswerIndex;

  Question({
    required this.question,
    required this.answers,
    required this.correctAnswerIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      answers: List<String>.from(json['answers']),
      correctAnswerIndex: json['correctAnswerIndex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answers': answers,
      'correctAnswerIndex': correctAnswerIndex,
    };
  }
}
class Answer extends StatelessWidget {
  final String answer;
  final VoidCallback onTap;

  const Answer({Key? key, required this.answer, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Text(
          answer,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc() : super(QuizLoading());

  @override
  Stream<QuizState> mapEventToState(QuizEvent event) async* {
    if (event is StartQuiz) {
      yield QuizLoading();
      try {
        Quiz quiz = await loadQuiz();
        yield QuizLoaded(quiz: quiz, currentQuestionIndex: 0, score: 0);
      } catch (e) {
        yield QuizError(error: e.toString());
      }
    } else if (event is AnswerSelected) {
      QuizLoaded currentState = state as QuizLoaded;
      Question currentQuestion = currentState.quiz.questions[currentState.currentQuestionIndex];
      if (currentQuestion.correctAnswerIndex == event.answerIndex) {
        int newScore = currentState.score + 1;
        if (currentState.currentQuestionIndex == currentState.quiz.questions.length - 1) {
          yield QuizFinished(score: newScore);
        } else {
          yield QuizLoaded(
              quiz: currentState.quiz,
              currentQuestionIndex: currentState.currentQuestionIndex + 1,
              score: newScore);
        }
      } else {
        yield QuizFinished(score: currentState.score);
      }
    }
  }

  Future<Quiz> loadQuiz() async {
    String jsonString =
        await rootBundle.loadString('assets/quiz.json');
    final jsonMap = json.decode(jsonString);
    return Quiz.fromJson(jsonMap);
  }
}

class QuizEvent {}

class StartQuiz extends QuizEvent {}

class AnswerSelected extends QuizEvent {
  final int answerIndex;

  AnswerSelected({required this.answerIndex});
}

class QuizState {}

class QuizLoading extends QuizState {}

class QuizLoaded extends QuizState {
  final Quiz quiz;
  final int currentQuestionIndex;
  final int score;

  QuizLoaded({required this.quiz, required this.currentQuestionIndex, required this.score});
}

class QuizFinished extends QuizState {
  final int score;

  QuizFinished({required this.score});
}

class Quiz {
  final List<Question> questions;

  Quiz({required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    List<Question> questions = [];
    for (var questionJson in json['questions']) {
      Question question = Question.fromJson(questionJson);
      questions.add(question);
    }
    return Quiz(questions: questions);
  }
}

class Question {
  final String question;
  final List<String> answers;
  final int correctAnswerIndex;

  Question({required this.question, required this.answers, required this.correctAnswerIndex});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      answers: List<String>.from(json['answers']),
      correctAnswerIndex: json['correctAnswerIndex'],
    );
  }
}

