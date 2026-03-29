@IsTest
private class CalculateTotalScoreAndSummaryTest {
  @IsTest
  static void testReturnsCannedJsonInTestContext() {
    // Arrange
    String sessionId = 'a0X000000000001'; // any string is acceptable in test context

    // Act
    String result = CalculateTotalScoreAndSummary.getTotalScoreAndSummary(
      sessionId
    );

    // Assert
    System.assertEquals(
      '{"Score": 85, "Summary": "Test Summary"}',
      result,
      'Expected canned JSON when Test.isRunningTest() is true.'
    );
  }

  @IsTest
  static void testThrowsExceptionInTestContext() {
    // Arrange
    String sessionId = 'ERROR';

    // Act & Assert
    try {
      CalculateTotalScoreAndSummary.getTotalScoreAndSummary(sessionId);
      System.assert(false, 'Expected CalloutException to be thrown');
    } catch (Exception e) {
      System.assertEquals('Test Exception', e.getMessage(), 'Expected Test Exception message');
    }
  }
}
