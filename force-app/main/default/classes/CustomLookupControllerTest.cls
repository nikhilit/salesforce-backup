@isTest
private class CustomLookupControllerTest {

    @isTest
    static void testSearch_WithSearchTermAndFilter() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Test.startTest();
        List<CustomLookupController.RecordWrapper> result = CustomLookupController.search(
            'Test', 'Account', 'Name != null', 'Name'
        );
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Result should not be empty');
    }

    @isTest
    static void testSearch_WithoutSearchTerm_WithFilter() {
        Account acc = new Account(Name = 'Filter Account');
        insert acc;

        Test.startTest();
        List<CustomLookupController.RecordWrapper> result = CustomLookupController.search(
            '', 'Account', 'Name != null', 'Name'
        );
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Result should not be empty');
    }

    @isTest
    static void testSearch_WithSearchTerm_WithoutFilter() {
        Account acc = new Account(Name = 'Search Account');
        insert acc;

        Test.startTest();
        List<CustomLookupController.RecordWrapper> result = CustomLookupController.search(
            'Search', 'Account', null, 'Name'
        );
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Result should not be empty');
    }

    @isTest
    static void testSearch_WithoutSearchTerm_WithoutFilter() {
        Account acc = new Account(Name = 'No Filter Account');
        insert acc;

        Test.startTest();
        List<CustomLookupController.RecordWrapper> result = CustomLookupController.search(
            '', 'Account', '', 'Name'
        );
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Result should not be empty');
    }

    @isTest
    static void testSearch_NullSearchTermAndFilter() {
        Account acc = new Account(Name = 'Nulls Test Account');
        insert acc;

        Test.startTest();
        List<CustomLookupController.RecordWrapper> result = CustomLookupController.search(
            null, 'Account', null, 'Name'
        );
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Result should not be empty');
    }
}