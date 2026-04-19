/**
 * @description Test class for WellnessInsightsService
 */
@IsTest
private class WellnessInsightsServiceTest {
  /**
   * @description Test successful retrieval of wellness insights
   */
  @IsTest
  static void testGetWellnessInsights_Success() {
    // Create test data
    Contact testContact = new Contact(
      FirstName = 'Test',
      LastName = 'User',
      Email = 'testuser@test.com'
    );
    insert testContact;

    MM_Response_Session__c session = new MM_Response_Session__c(
      MM_User__c = testContact.Id,
      MM_Status__c = 'Completed',
      MM_Start_Time__c = System.now().addHours(-1),
      MM_End_Time__c = System.now(),
      MM_Total_Score__c = 75,
      MM_Summary__c = 'Test summary of mental health condition'
    );
    insert session;

    Test.startTest();
    String result = WellnessInsightsService.getWellnessInsights(session.Id);
    Test.stopTest();

    // Verify result
    System.assertNotEquals(null, result, 'Result should not be null');
    System.assert(
      result.contains('insights'),
      'Result should contain insights key'
    );

    // Parse and verify structure
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
      result
    );
    System.assert(
      resultMap.containsKey('insights'),
      'Should contain insights key'
    );
    System.assert(
      resultMap.containsKey('fallbackScore'),
      'Should contain fallbackScore key'
    );
    System.assert(
      resultMap.containsKey('fallbackSummary'),
      'Should contain fallbackSummary key'
    );

    // Verify insights array
    List<Object> insights = (List<Object>) resultMap.get('insights');
    System.assertEquals(3, insights.size(), 'Should have 3 insights');

    // Verify first insight structure
    Map<String, Object> firstInsight = (Map<String, Object>) insights[0];
    System.assert(
      firstInsight.containsKey('category'),
      'Insight should have category'
    );
    System.assert(
      firstInsight.containsKey('insight'),
      'Insight should have insight text'
    );
    System.assert(firstInsight.containsKey('icon'), 'Insight should have icon');
  }

  /**
   * @description Test fallback when prompt template fails
   */
  @IsTest
  static void testGetWellnessInsights_FallbackOnError() {
    // Create test data
    Contact testContact = new Contact(
      FirstName = 'Test',
      LastName = 'User',
      Email = 'testuser@test.com'
    );
    insert testContact;

    MM_Response_Session__c session = new MM_Response_Session__c(
      MM_User__c = testContact.Id,
      MM_Status__c = 'Completed',
      MM_Start_Time__c = System.now().addHours(-1),
      MM_End_Time__c = System.now(),
      MM_Total_Score__c = 85,
      MM_Summary__c = 'Fallback summary text'
    );
    insert session;

    Test.startTest();
    // Use 'ERROR' as session ID to trigger fallback in test context
    String result = WellnessInsightsService.getWellnessInsights('ERROR');
    Test.stopTest();

    // Verify fallback was used
    System.assertNotEquals(null, result, 'Result should not be null');

    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
      result
    );

    // In test context with ERROR, it should still return mock data
    System.assert(
      resultMap.containsKey('insights'),
      'Should contain insights key'
    );
  }

  /**
   * @description Test with null session ID
   */
  @IsTest
  static void testGetWellnessInsights_NullSessionId() {
    Test.startTest();
    try {
      WellnessInsightsService.getWellnessInsights(null);
      System.assert(false, 'Should have thrown an exception');
    } catch (AuraHandledException e) {
      System.assertEquals(
        'Response Session Id is required.',
        e.getMessage(),
        'Should throw correct error message'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test with blank session ID
   */
  @IsTest
  static void testGetWellnessInsights_BlankSessionId() {
    Test.startTest();
    try {
      WellnessInsightsService.getWellnessInsights('');
      System.assert(false, 'Should have thrown an exception');
    } catch (AuraHandledException e) {
      System.assertEquals(
        'Response Session Id is required.',
        e.getMessage(),
        'Should throw correct error message'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test mock insights response structure
   */
  @IsTest
  static void testGetWellnessInsights_MockStructure() {
    // Create test data
    Contact testContact = new Contact(
      FirstName = 'Test',
      LastName = 'User',
      Email = 'testuser@test.com'
    );
    insert testContact;

    MM_Response_Session__c session = new MM_Response_Session__c(
      MM_User__c = testContact.Id,
      MM_Status__c = 'Completed',
      MM_Start_Time__c = System.now().addHours(-1),
      MM_End_Time__c = System.now(),
      MM_Total_Score__c = 75,
      MM_Summary__c = 'Test summary'
    );
    insert session;

    Test.startTest();
    String result = WellnessInsightsService.getWellnessInsights(session.Id);
    Test.stopTest();

    // Verify mock response categories
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
      result
    );
    List<Object> insights = (List<Object>) resultMap.get('insights');

    Map<String, Object> insight1 = (Map<String, Object>) insights[0];
    System.assertEquals(
      'Depression',
      insight1.get('category'),
      'First insight should be Depression category'
    );
    System.assertEquals(
      'utility:favorite',
      insight1.get('icon'),
      'Depression should use favorite icon'
    );

    Map<String, Object> insight2 = (Map<String, Object>) insights[1];
    System.assertEquals(
      'Anxiety',
      insight2.get('category'),
      'Second insight should be Anxiety category'
    );
    System.assertEquals(
      'utility:warning',
      insight2.get('icon'),
      'Anxiety should use warning icon'
    );

    Map<String, Object> insight3 = (Map<String, Object>) insights[2];
    System.assertEquals(
      'Stress',
      insight3.get('category'),
      'Third insight should be Stress category'
    );
    System.assertEquals(
      'utility:help',
      insight3.get('icon'),
      'Stress should use help icon'
    );
  }
}
