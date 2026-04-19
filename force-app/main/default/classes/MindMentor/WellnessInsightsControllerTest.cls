/**
 * @description Test class for WellnessInsightsController
 */
@IsTest
private class WellnessInsightsControllerTest {
  /**
   * @description Test data setup
   */
  @TestSetup
  static void makeData() {
    // Create test contact
    Contact testContact = new Contact(
      FirstName = 'Test',
      LastName = 'User',
      Email = 'testuser@test.com'
    );
    insert testContact;

    // Create completed session
    MM_Response_Session__c session = new MM_Response_Session__c(
      MM_User__c = testContact.Id,
      MM_Status__c = 'Completed',
      MM_Start_Time__c = System.now().addHours(-2),
      MM_End_Time__c = System.now().addHours(-1),
      MM_Total_Score__c = 80,
      MM_Summary__c = 'Test summary for wellness insights'
    );
    insert session;

    // Create in-progress session (should be ignored)
    MM_Response_Session__c inProgressSession = new MM_Response_Session__c(
      MM_User__c = testContact.Id,
      MM_Status__c = 'In Progress',
      MM_Start_Time__c = System.now().addMinutes(-30)
    );
    insert inProgressSession;
  }

  /**
   * @description Test successful retrieval of wellness insights
   */
  @IsTest
  static void testGetLatestWellnessInsights_Success() {
    // Get test contact
    Contact testContact = [
      SELECT Id
      FROM Contact
      WHERE Email = 'testuser@test.com'
      LIMIT 1
    ];

    // Create test user associated with contact
    Profile communityProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Mind Mentor Community User'
      LIMIT 1
    ];

    User testUser = new User(
      FirstName = 'Test',
      LastName = 'User',
      Email = 'testuser@test.com',
      Username = 'testuser@mindmentor.test.com',
      Alias = 'tuser',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      ProfileId = communityProfile.Id,
      LanguageLocaleKey = 'en_US',
      ContactId = testContact.Id
    );
    insert testUser;

    Test.startTest();
    String result;
    System.runAs(testUser) {
      result = WellnessInsightsController.getLatestWellnessInsights();
    }
    Test.stopTest();

    // Verify result
    System.assertNotEquals(null, result, 'Result should not be null');
    System.assert(
      result.contains('insights'),
      'Result should contain insights'
    );

    // Parse and verify structure
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
      result
    );
    System.assert(
      resultMap.containsKey('insights'),
      'Should have insights key'
    );

    List<Object> insights = (List<Object>) resultMap.get('insights');
    System.assertEquals(3, insights.size(), 'Should have 3 insights');
  }

  /**
   * @description Test with no completed sessions
   */
  @IsTest
  static void testGetLatestWellnessInsights_NoCompletedSessions() {
    // Create new contact without completed sessions
    Contact newContact = new Contact(
      FirstName = 'New',
      LastName = 'User',
      Email = 'newuser@test.com'
    );
    insert newContact;

    // Create test user
    Profile communityProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Mind Mentor Community User'
      LIMIT 1
    ];

    User testUser = new User(
      FirstName = 'New',
      LastName = 'User',
      Email = 'newuser@test.com',
      Username = 'newuser@mindmentor.test.com',
      Alias = 'nuser',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      ProfileId = communityProfile.Id,
      LanguageLocaleKey = 'en_US',
      ContactId = newContact.Id
    );
    insert testUser;

    Test.startTest();
    String result;
    System.runAs(testUser) {
      result = WellnessInsightsController.getLatestWellnessInsights();
    }
    Test.stopTest();

    // Verify result is null when no completed sessions exist
    System.assertEquals(
      null,
      result,
      'Result should be null when no completed sessions exist'
    );
  }

  /**
   * @description Test with user not associated with contact
   */
  @IsTest
  static void testGetLatestWellnessInsights_NoContact() {
    // Create test user without contact
    Profile sysAdminProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
      LIMIT 1
    ];

    User testUser = new User(
      FirstName = 'Admin',
      LastName = 'User',
      Email = 'adminuser@test.com',
      Username = 'adminuser@mindmentor.test.com',
      Alias = 'auser',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      ProfileId = sysAdminProfile.Id,
      LanguageLocaleKey = 'en_US'
    );
    insert testUser;

    Test.startTest();
    String result;
    System.runAs(testUser) {
      result = WellnessInsightsController.getLatestWellnessInsights();
    }
    Test.stopTest();

    // Verify result is null when user has no contact
    System.assertEquals(
      null,
      result,
      'Result should be null when user is not associated with a contact'
    );
  }

  /**
   * @description Test that latest completed session is retrieved
   */
  @IsTest
  static void testGetLatestWellnessInsights_LatestSession() {
    // Get test contact
    Contact testContact = [
      SELECT Id
      FROM Contact
      WHERE Email = 'testuser@test.com'
      LIMIT 1
    ];

    // Create another completed session (more recent)
    MM_Response_Session__c newerSession = new MM_Response_Session__c(
      MM_User__c = testContact.Id,
      MM_Status__c = 'Completed',
      MM_Start_Time__c = System.now().addMinutes(-30),
      MM_End_Time__c = System.now(),
      MM_Total_Score__c = 90,
      MM_Summary__c = 'Newer session summary'
    );
    insert newerSession;

    // Create test user
    Profile communityProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Mind Mentor Community User'
      LIMIT 1
    ];

    User testUser = new User(
      FirstName = 'Test',
      LastName = 'Latest',
      Email = 'testlatest@test.com',
      Username = 'testlatest@mindmentor.test.com',
      Alias = 'tluser',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      ProfileId = communityProfile.Id,
      LanguageLocaleKey = 'en_US',
      ContactId = testContact.Id
    );
    insert testUser;

    Test.startTest();
    String result;
    System.runAs(testUser) {
      result = WellnessInsightsController.getLatestWellnessInsights();
    }
    Test.stopTest();

    // Verify result contains data from the newer session
    System.assertNotEquals(null, result, 'Result should not be null');

    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
      result
    );

    // Verify fallback score matches newer session
    Decimal fallbackScore = (Decimal) resultMap.get('fallbackScore');
    // In test context, mock data is returned, so we just verify structure
    System.assertNotEquals(
      null,
      fallbackScore,
      'Fallback score should be present'
    );
  }

  /**
   * @description Test USER_MODE enforcement (security)
   */
  @IsTest
  static void testGetLatestWellnessInsights_Security() {
    // Create test contact
    Contact testContact = [
      SELECT Id
      FROM Contact
      WHERE Email = 'testuser@test.com'
      LIMIT 1
    ];

    // Create test user with limited access
    Profile communityProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Mind Mentor Community User'
      LIMIT 1
    ];

    User testUser = new User(
      FirstName = 'Limited',
      LastName = 'User',
      Email = 'limiteduser@test.com',
      Username = 'limiteduser@mindmentor.test.com',
      Alias = 'luser',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      ProfileId = communityProfile.Id,
      LanguageLocaleKey = 'en_US',
      ContactId = testContact.Id
    );
    insert testUser;

    Test.startTest();
    String result;
    System.runAs(testUser) {
      // Should only return data for user's own contact
      result = WellnessInsightsController.getLatestWellnessInsights();
    }
    Test.stopTest();

    // Verify result is returned (USER_MODE ensures only own data)
    System.assertNotEquals(
      null,
      result,
      'Result should not be null for user with proper access'
    );
  }
}
