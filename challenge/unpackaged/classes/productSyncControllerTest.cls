@isTest
private class productSyncControllerTest {

    @isTest
    static void testGetAccessTokenSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockDataUtility.MockSuccessLoginCallout());

        Test.startTest();
        String token = productSyncController.getAccessToken();
        Test.stopTest();

        System.assertEquals('testToken123', token, 'The returned token should match the mocked token');
    }

    @isTest
    static void testGetAccessTokenFailure() {
        Test.setMock(HttpCalloutMock.class, new MockDataUtility.MockFailedLoginCallout());

        try {
            Test.startTest();
            productSyncController.getAccessToken();
            Test.stopTest();
            System.assert(false, 'Expected CalloutException was not thrown.');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Login failed'), 'Expected login failure message');
        }
    }

    @isTest
    static void testSyncProducts() {
        Test.setMock(HttpCalloutMock.class, new MockDataUtility.MockProductSyncCallout());

        Test.startTest();
        productSyncController.syncProducts();
        Test.stopTest();

        List<DummyProduct__c> products = [SELECT Id, Name FROM DummyProduct__c];
        System.assertEquals(2, products.size(), 'There should be 2 products inserted.');
        List<Review__c> reviews = [SELECT Id, Name FROM Review__c];
        System.assertEquals(2, reviews.size(), 'There should be 2 reviews inserted.');
        List<Product_Image__c> images = [SELECT Id, Name FROM Product_Image__c];
        System.assertEquals(3, images.size(), 'There should be 3 images inserted.');
    }
    
}