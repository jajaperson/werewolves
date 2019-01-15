#!/usr/bin/env dart

// ======================
// IMPORTS
// ======================

import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:args/args.dart';
import 'package:ansicolor/ansicolor.dart';

// ======================
// MAIN
// ======================

AnsiPen error = new AnsiPen()..red(bold: true);
AnsiPen key = new AnsiPen()..blue();
AnsiPen dealer = new AnsiPen()..cyan(bold: true);

ArgResults argResults;

var dealings = <String, Rank>{};

void main(List<String> arguments) {
  final parser = new ArgParser()
    ..addFlag('narrator', abbr: 'n', defaultsTo: false);

  argResults = parser.parse(arguments);
  int players = int.parse(argResults.rest.length > 0 ? argResults.rest[0] : '0');

  werewolves(players, argResults['narrator']);
}

Future werewolves(int players, bool narrator) async {
  int _required = 6;
  if (narrator) _required++;

  if (players < _required) {
    stderr.writeln(error('Not enough players.'));
    exit(6);
  } else {
//    print("\x1B[2J\x1B[0;0H");
    Deck deck = new Deck({
      Rank.narrator: _required - 6,
      Rank.werewolf: 2,
      Rank.detective: 2,
      Rank.vicar: 1,
      Rank.villager: players - _required + 1
    });
    assert(deck.contents.length == players);
    stdout.writeln('Created Deck :: ${deck.contents}');
    stdout.write('Shuffling ');
    stdout.write('.');
    deck.shuffle(); // Not needed, but why the hell not?
    stdout.write('.');
    deck.shuffle(); // One more for good luck.
    stdout.writeln('.');
    stdout.writeln('Shuffling completed!');
    stdout.write('Ready to deal. Press ${key('<return>')} to continue. ');
    stdin.readLineSync();
    print('\x1B[2J\x1B[0;0H');
    while (deck.cards != 0) {
      var name = '';
      while (true) {
        stdout.write('Please enter your name followed by ${key('<return>')}: ');
        name = stdin.readLineSync();
        if (dealings[name] == null) {
          break;
        } else {
          stdout.writeln(error('The name "$name" is already taken. Please '
              'select a unique one.'));
        }
      }
      stdout.writeln('$name, your card is: \n');
      Rank card = deck.drawRandom();
      AsciiCard asciiCard = new AsciiCard.fromRank(card);
      stdout.writeln(asciiCard);
      dealings[name] = card;
      stdout.write(
          'Ready for next player. Press ${key('<return>')} to clear the'
          ' screen (IMPORTANT: don\'t let anyone see the screen until you have '
          'done this!) ');
      stdin.readLineSync();
      stdout.writeln('\x1B[2J\x1B[0;0H');
    }
    stdout.writeln('Dealing complete! Type ${key('reveal')} followed by '
        '${key('<return>')} to list roles assigned to names, or ${key('exit')} '
        'followed by ${key('<return>')}');
    while (true) {
      stdout.write(': ');
      String cmd = stdin.readLineSync().toLowerCase();
      if (cmd == 'reveal') {
        dealings.forEach((name, card) => stdout.writeln('${dealer(name)} was ${dealer(card.toString())}.'));
      } else if (cmd == 'exit') {
        break;
      } else if (cmd == 'clear') {
        stdout.writeln('\x1B[2J\x1B[0;0H');
      } else if (cmd == 'help') {
        stdout.writeln('''
${key('reveal')} :: reveal roles assigned to names
${key('exit')}   :: exit program
${key('help')}   :: list commands
${key('clear')}  :: clear the screen''');
      } else if (cmd != '') {
        stdout.writeln(error('Unknown command. Type ')
            + key('help')
            + error(' followed by ')
            + key('<return>')
            + error(' for a list of known commands.'));
      }
    }
  }
}

// ======================
// CARDS
// ======================

enum Rank { narrator, werewolf, detective, vicar, villager }

class Deck {
  final Map<Rank, int> options;
  var contents = <Rank>[];
  Random _rand = new Random();

  Deck(this.options) {
    options.forEach(addToDeck);
  }

  // Get the number of cards in the deck.
  int get cards => contents.length;

  // Add a card to the deck.
  void addToDeck(Rank card, int qty) {
    for (var i = 0; i < qty; i++) {
      contents.add(card);
    }
  }

  // Shuffle the Deck.
  void shuffle() {
    contents.shuffle();
  }

  // Remove a card from a specified position in the deck and return its value.
  Rank draw(int index) {
    assert(index < cards - 1);
    return contents.removeAt(index);
  }

  // Take a card from a specified position in the deck, return its value, and
  //  move it to the bottom of the deck.
  Rank look(int index) {
    assert(index < cards - 1);
    Rank card = draw(index);
    contents.insert(0, card);
    return card;
  }

  // Draw a card from the top of the deck.
  Rank drawTop() => draw(cards - 1);

  // Take a card from the top of the deck and move it to the bottom.
  Rank top() => look(cards - 1);

  // Draw a card randomly.
  Rank drawRandom() => draw(cards < 1 ? _rand.nextInt(cards - 1) : 0);

  // Take a random card and move it to the bottom.
  Rank random() => look(cards < 1 ? _rand.nextInt(cards - 1) : 0);
}

class AsciiCard {
  String word;
  int height = 9;

  AsciiCard(this.word);

  AsciiCard.fromRank(Rank card) {
    switch (card) {
      case Rank.narrator:
        word = 'Narrator';
        break;
      case Rank.werewolf:
        word = 'Werewolf';
        break;
      case Rank.detective:
        word = 'Detective';
        break;
      case Rank.vicar:
        word = '† Vicar';
        break;
      default:
        word = 'Villager';
    }
  }

  int get width {
    if (word.length <= 10) {
      return 22;
    } else {
      return 12 + word.length;
    }
  }

  String toString() {
    String border = '+';
    String padding = '|';
    for (var i = 0; i < width - 2; i++) {
      border += '-';
      padding += ' ';
    }
    border += '+\n';
    padding += '|\n';
    String line = padding.substring(0, ((width - word.length) / 2).floor());
    line += word;
    line += padding.substring(line.length);
    String _asciiCard = '';
    for (var i = 0; i < height; i++) {
      if (i == 0 || i == height - 1) {
        _asciiCard += border;
      } else if (i + 1 == (height / 2).ceil()) {
        _asciiCard += line;
      } else {
        _asciiCard += padding;
      }
    }
    return _asciiCard;
  }
}
