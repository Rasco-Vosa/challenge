public with sharing class productQueryController {
    
    public class FilterWrapper {
        public String productName;
        public String brand;
        public Decimal minPrice;
        public Decimal maxPrice;
        public Decimal minRating;
        public String category;
    }

    @AuraEnabled(cacheable=true)
    public static List<Id> getEligibleProductIds() {
        Set<Id> eligibleProductIds = new Set<Id>();
        List<DummyProduct__c> allProducts = [
            SELECT Id, Category__c, Price__c 
            FROM DummyProduct__c 
            ORDER BY Price__c ASC
        ];
    
        Map<String, List<DummyProduct__c>> productsByCategory = new Map<String, List<DummyProduct__c>>();
        Map<String, Decimal> categoryPriceSums = new Map<String, Decimal>();
    
        for (DummyProduct__c p : allProducts) {
            String category = p.Category__c;
            if (!productsByCategory.containsKey(category)) {
                productsByCategory.put(category, new List<DummyProduct__c>());
                categoryPriceSums.put(category, 0);
            }
    
            List<DummyProduct__c> categoryProds = productsByCategory.get(category);
            Decimal currentSum = categoryPriceSums.get(category);
            Decimal price = p.Price__c != null ? p.Price__c : 0;
    
            if (categoryProds.size() < 100 && currentSum + price < 10000) {
                categoryProds.add(p);
                categoryPriceSums.put(category, currentSum + price);
                eligibleProductIds.add(p.Id);
            }
        }
    
        return new List<Id>(eligibleProductIds);
    }
    

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProducts(Integer limitSize, Integer offsetSize, String filtersJson, List<Id> eligibleProductIds) {
        
        FilterWrapper filters = (FilterWrapper) JSON.deserialize(filtersJson, FilterWrapper.class);
        /* ---- 1. Querying Products with Filters, Pagination & Eligible Ids ----*/
        // Base query
        String baseQuery = 'SELECT Id, Name, Brand__c, Category__c, Price__c, Rating__c, Thumbnail__c, Stock__c FROM DummyProduct__c WHERE Id IN :eligibleProductIds';
        
        // Store filter Conditions 
        String queryConditions = '';
        List<String> conditions = new List<String>();
        if (String.isNotBlank(filters.productName)) {
            conditions.add('Name LIKE \'%' + String.escapeSingleQuotes(filters.productName) + '%\'');
        }
        if (String.isNotBlank(filters.brand)) {
            conditions.add('Brand__c = \'' + String.escapeSingleQuotes(filters.brand) + '\'');
        }
        if (filters.minPrice != null) {
            conditions.add('Price__c >= ' + filters.minPrice);
        }
        if (filters.maxPrice != null) {
            conditions.add('Price__c <= ' + filters.maxPrice);
        }
        if (filters.minRating != null) {
            conditions.add('Rating__c >= ' + filters.minRating);
        }
        if (String.isNotBlank(filters.category)) {
            conditions.add('Category__c = \'' + String.escapeSingleQuotes(filters.category) + '\'');
        }
        if (!conditions.isEmpty()) {
            queryConditions += ' AND ' + String.join(conditions, ' AND ');
        }
        
        // Add pagination
        String query = baseQuery + queryConditions + ' LIMIT :limitSize OFFSET :offsetSize';
    
        // Execute the query
        List<DummyProduct__c> results = Database.query(query);


        /* ---- 2. Check Products in Stock (In View) ----*/
        Integer productsInStock = 0;
        for (DummyProduct__c product : results){
            if (product.Stock__c >= 1){
                productsInStock++;
            }
        }
        

        /* ---- 3. Get the Total Number of Products ----*/
        String totalCountQuery = 'SELECT COUNT() FROM DummyProduct__c WHERE Id IN :eligibleProductIds' + queryConditions ;
        Integer totalCount = Database.countQuery(totalCountQuery);


        return new Map<String, Object>{
            'products' => results,
            'productsInStock' => productsInStock,
            'totalCount' => totalCount
        };
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getFilterPicklistValues() {
        Set<String> brands = new Set<String>();
        Set<String> categories = new Set<String>();

        List <DummyProduct__c> products = [SELECT Brand__c, Category__c FROM DummyProduct__c];
        for (DummyProduct__c product : products) {
            if (product.Brand__c != null) brands.add(product.Brand__c);
            if (product.Category__c != null) categories.add(product.Category__c);
        }

        return new Map<String, List<String>>{
            'brands' => new List<String>(brands),
            'categories' => new List<String>(categories)
        };
    }


}