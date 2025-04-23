@isTest
private class productQueryControllerTest {

    @testSetup
    static void setupTestData() {
        List<DummyProduct__c> products = new List<DummyProduct__c>();

        // 1. Electronics Category (All Eligible)
        Integer idCounter = 1; 
        for (Integer i = 0; i < 10; i++) {
            products.add(new DummyProduct__c(
                Name = 'Phone ' + i,
                Category__c = 'Electronics',
                Price__c = 50*i,
                Rating__c = 3 + (i*0.15),
                Brand__c = 'Brand A',
                Stock__c = 2,
                ExternalId__c = idCounter
            ));
            idCounter++;
        }

        // 2. Books Category (1 Product Exceeds Price Limit)
        for (Integer i = 0; i < 5; i++) {
            products.add(new DummyProduct__c(
                Name = 'Book ' + i,
                Category__c = 'Books',
                Price__c = 1000*i,
                Rating__c = 3,
                Brand__c = 'Brand B',
                Stock__c = 2,
                ExternalId__c = idCounter
            ));
            idCounter++;
        }

        // 3. Toys Category (Eligible but out of stock)
        for (Integer i = 0; i < 5; i++) {
            products.add(new DummyProduct__c(
                Name = 'Toy ' + i,
                Category__c = 'Toys',
                Price__c = 100,
                Rating__c = null,
                Brand__c = 'Brand C',
                Stock__c = 0,
                ExternalId__c = idCounter
            ));
            idCounter++;
        }

        insert products;
    }

    
    @isTest
    static void testGetEligibleProductIds() {
        Test.startTest();
        List<Id> result = productQueryController.getEligibleProductIds();
        Test.stopTest();
        System.assertEquals(19, result.size(), 'There should be 19 eligible ids');
    }

    @isTest
    static void testGetProducts_HappyPath() {
        List<Id> eligibleIds = productQueryController.getEligibleProductIds();

        // Prepare filters JSON
        productQueryController.FilterWrapper filterObj = new productQueryController.FilterWrapper();
        filterObj.productName = 'Phone';
        filterObj.brand = 'Brand A';
        filterObj.minPrice = 20;
        filterObj.maxPrice = 1000;
        filterObj.minRating = 2.5;
        filterObj.category = 'Electronics';

        String filtersJson = JSON.serialize(filterObj);

        Test.startTest();
        Map<String, Object> results = productQueryController.getProducts(8, 0, filtersJson, eligibleIds);
        Test.stopTest();

        System.assertEquals(8, ((List<DummyProduct__c>) results.get('products')).size(), 'There should be 8 products');
        System.assertEquals(9, results.get('totalCount'), 'Should have 9 total products');
        System.assertEquals(8, results.get('productsInStock'), 'Should have 8 products in stock');

    }

    @isTest
    static void testGetProducts_NullFilters() {
        List<Id> eligibleIds = productQueryController.getEligibleProductIds();

        // Create a NULL filter object
        productQueryController.FilterWrapper filterObj = new productQueryController.FilterWrapper();
        String filtersJson = JSON.serialize(filterObj);

        Test.startTest();
        Map<String, Object> results = productQueryController.getProducts(20, 0, filtersJson, eligibleIds);
        Test.stopTest();

        //Note: The values are affected by eligible ids as well
        System.assertEquals(19, ((List<DummyProduct__c>) results.get('products')).size(), 'There should be 20 products');
        System.assertEquals(19, results.get('totalCount'), 'Should have 20 total products');
        System.assertEquals(14, results.get('productsInStock'), 'Should have 15 products in stock');
    }

    @isTest
    static void testGetProducts_InvalidFilters() {
        List<Id> eligibleIds = productQueryController.getEligibleProductIds();

        Test.startTest();
        try {
            productQueryController.getProducts(10, 0, 'invalid-json', eligibleIds);
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    static void testGetProducts_Pagination() {
        List<Id> eligibleIds = productQueryController.getEligibleProductIds();

        productQueryController.FilterWrapper filterObj = new productQueryController.FilterWrapper();
        String filtersJson = JSON.serialize(filterObj);

        Map<String, Object> page1 = productQueryController.getProducts(5, 0, filtersJson, eligibleIds);
        Map<String, Object> page2 = productQueryController.getProducts(5, 5, filtersJson, eligibleIds);

        List<DummyProduct__c> list1 = (List<DummyProduct__c>) page1.get('products');
        List<DummyProduct__c> list2 = (List<DummyProduct__c>) page2.get('products');

        System.assertEquals(5, list1.size());
        System.assertEquals(5, list2.size());
        System.assertNotEquals(list1[0].Id, list2[0].Id, 'Page 1 and Page 2 should have different items');
    }

    @isTest
    static void testGetProducts_EmptyEligibleIds() {
        List<Id> emptyIds = new List<Id>();

        productQueryController.FilterWrapper filterObj = new productQueryController.FilterWrapper();
        String filtersJson = JSON.serialize(filterObj);

        Test.startTest();
        Map<String, Object> results = productQueryController.getProducts(10, 0, filtersJson, emptyIds);
        Test.stopTest();

        List<DummyProduct__c> products = (List<DummyProduct__c>) results.get('products');
        System.assertEquals(0, products.size(), 'Should return no products when eligibleIds is empty');
        System.assertEquals(0, results.get('productsInStock'), 'No products should be in stock');
        System.assertEquals(0, results.get('totalCount'), 'Total count should be zero');
    }

    @isTest
    static void testGetFilterPicklistValues() {
        Test.startTest();
        Map<String, List<String>> picklists = productQueryController.getFilterPicklistValues();
        Test.stopTest();

        Map<String, List<String>> picklistsTest = new Map<String, List<String>>{
            'brands' => new List<String>{'Brand A', 'Brand B', 'Brand C'},
            'categories' => new List<String>{'Electronics', 'Books', 'Toys'}
        };

        System.assertEquals(picklistsTest, picklists,'Should return brand list');

    }
}