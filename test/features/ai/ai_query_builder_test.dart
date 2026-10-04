import 'package:college_os/features/ai/domain/ai_query_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiQueryBuilder', () {
    test(
      'turns a natural-language question into an OR\'d prefix expression',
      () {
        final expression = AiQueryBuilder.buildFtsExpression(
          'What is the working principle of a PN junction diode?',
        );

        expect(expression, isNotNull);
        // OR, not AND: requiring every word of a sentence to appear on one page
        // would match nothing.
        expect(expression, contains(' OR '));
        expect(expression, contains('junction*'));
        expect(expression, contains('diode*'));
        expect(expression, contains('principle*'));
      },
    );

    test('drops question scaffolding that carries no retrieval signal', () {
      final expression = AiQueryBuilder.buildFtsExpression(
        'Explain ion exchange method from my chemistry notes.',
      );

      expect(expression, 'ion* OR exchange* OR method* OR chemistry*');
    });

    test('keeps a topical word even when it looks like question framing', () {
      // "advantages" is the whole subject of this question, so dropping it as a
      // stopword would turn a real question into "nothing found".
      final expression = AiQueryBuilder.buildFtsExpression(
        'What are the advantages of this topic?',
      );

      expect(expression, 'advantages*');
    });

    test('removes duplicates while keeping the first-seen order', () {
      final terms = AiQueryBuilder.extractTerms('diode diode junction diode');

      expect(terms, ['diode', 'junction']);
    });

    test(
      'caps the number of terms so a long question cannot match everything',
      () {
        final terms = AiQueryBuilder.extractTerms(
          'alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi',
          maxTerms: 4,
        );

        expect(terms, ['alpha', 'beta', 'gamma', 'delta']);
      },
    );

    test('ignores single characters that would match almost any page', () {
      final terms = AiQueryBuilder.extractTerms('a I o x diode');

      expect(terms, ['diode']);
    });

    test('strips punctuation and Unicode-unsafe characters', () {
      final expression = AiQueryBuilder.buildFtsExpression(
        'semiconductors; "doping" — (n-type)!',
      );

      expect(expression, isNotNull);
      expect(expression, isNot(contains('"')));
      expect(expression, isNot(contains('(')));
      expect(expression, isNot(contains('!')));
      expect(expression, contains('semiconductors*'));
      expect(expression, contains('doping*'));
    });

    test('returns null when the question has nothing searchable', () {
      expect(AiQueryBuilder.buildFtsExpression('what is this'), isNull);
      expect(AiQueryBuilder.buildFtsExpression(''), isNull);
      expect(AiQueryBuilder.buildFtsExpression('   ?!  '), isNull);
    });
  });
}
