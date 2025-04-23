public with sharing class productSyncController {

    public class ProductListWrapper {
        public List<ProductWrapper> products;
    }

    public class ProductWrapper {
        public Integer id;
        public String title;
        public String description;
        public String category;
        public Decimal price;
        public Decimal discountPercentage;
        public Decimal rating;
        public Integer stock;
        public List<String> tags;
        public String brand;
        public String sku;
        public Decimal weight;
        public DimensionsWrapper dimensions;
        public String warrantyInformation;
        public String shippingInformation;
        public String availabilityStatus;
        public List<ReviewWrapper> reviews;
        public String returnPolicy;
        public Integer minimumOrderQuantity;
        public MetaWrapper meta;
        public List<String> images;
        public String thumbnail;
    }

    public class DimensionsWrapper {
        public Decimal width;
        public Decimal height;
        public Decimal depth;
    }

    public class MetaWrapper {
        public String barcode;
        public String qrCode;
    }

    public class ReviewWrapper {
        public Integer rating;
        public String comment;
        public String reviewDate; 
        public String reviewerName;
        public String reviewerEmail;
    }
    
    public class LoginResponse {
        public String token;
        public String refreshToken;
        public String id;
        public String username;
    }

    @AuraEnabled
    public static void syncProducts() {
        String accessToken = getAccessToken();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:DummyJson/products?limit=0');
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Accept', 'application/json');
        HttpResponse res = http.send(request);
        
        if (res.getStatusCode() == 200) {
            ProductListWrapper response = (ProductListWrapper) JSON.deserialize(res.getBody(), ProductListWrapper.class);
            List<DummyProduct__c> productsToInsert = new List<DummyProduct__c>();
            List<Review__c> reviewsToInsert = new List<Review__c>();
            List<Product_Image__c> imagesToInsert = new List<Product_Image__c>();

            for (ProductWrapper productInfo : response.products) {
                DummyProduct__c product = new DummyProduct__c();
                product.ExternalId__c = productInfo.id;
                product.Name = productInfo.title;
                product.Description__c = productInfo.description;
                product.Category__c = productInfo.category;
                product.Price__c = productInfo.price;
                product.DiscountPercentage__c = productInfo.discountPercentage;
                product.Rating__c = productInfo.rating;
                product.Stock__c = productInfo.stock;
                product.Brand__c = productInfo.brand;
                product.SKU__c = productInfo.sku;
                product.Weight__c = productInfo.weight;
                product.WarrantyInformation__c = productInfo.warrantyInformation;
                product.ShippingInformation__c = productInfo.shippingInformation;
                product.AvailabilityStatus__c = productInfo.availabilityStatus;
                product.ReturnPolicy__c = productInfo.returnPolicy;
                product.MinimumOrderQuantity__c = productInfo.minimumOrderQuantity;
                product.thumbnail__c = productInfo.thumbnail;
                product.Barcode__c = productInfo.meta != null ? productInfo.meta.barcode : null;
                product.QRCode__c = productInfo.meta != null ? productInfo.meta.qrCode : null;
                product.TagsList__c = productInfo.tags != null ? String.join(productInfo.tags, ';') + ';' : null;

                if (productInfo.dimensions != null) {
                    product.Width__c = productInfo.dimensions.width;
                    product.Height__c = productInfo.dimensions.height;
                    product.Depth__c = productInfo.dimensions.depth;
                }

                productsToInsert.add(product);
            }

            if (!productsToInsert.isEmpty()) {
                upsert productsToInsert ExternalId__c;

                // Link reviews and images after insertion
                for (Integer i = 0; i < productsToInsert.size(); i++) {
                    DummyProduct__c insertedProduct = productsToInsert[i];
                    ProductWrapper productInfo = response.products[i];

                    // Handle reviews
                    if (productInfo.reviews != null) {
                        Integer reviewCounter = 0;
                        for (ReviewWrapper r : productInfo.reviews) {
                            Review__c review = new Review__c();
                            review.ExternalId__c = productInfo.id + 'R' + reviewCounter;
                            review.Name = insertedProduct.Name + r.reviewerName;
                            review.Rating__c = r.rating;
                            review.Comment__c = r.comment;
                            review.Reviewer_Name__c = r.reviewerName;
                            review.ReviewerEmail__c = r.reviewerEmail;
                            review.DummyProduct__c = insertedProduct.Id;

                            try {
                                review.Date__c = !String.isBlank(r.reviewDate) ? DateTime.valueOf(r.reviewDate) : null;
                            } catch (Exception e) {
                                System.debug('Invalid review date: ' + r.reviewDate);
                            }
                            reviewsToInsert.add(review);
                            reviewCounter++;
                        }
                    }

                    // Handle images
                    if (productInfo.images != null) {
                        Integer imageCounter = 0;
                        for (String imageUrl : productInfo.images) {
                            if (String.isNotBlank(imageUrl)) {
                                Product_Image__c image = new Product_Image__c();
                                image.ExternalId__c = productInfo.id + 'I' + imageCounter;
                                image.Name = insertedProduct.Name + ' ' + imageCounter; 
                                image.URL__c = imageUrl;
                                image.DummyProduct__c = insertedProduct.Id;
                                imagesToInsert.add(image);
                            }
                            imageCounter++;
                        }    
                    }
                }

                if (!reviewsToInsert.isEmpty()) upsert reviewsToInsert ExternalId__c;
                if (!imagesToInsert.isEmpty()) upsert imagesToInsert ExternalId__c;
            }
        } else {
            System.debug('Failed to fetch products: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
    }

    // Public method to get the access token
    public static String getAccessToken() {
        
        // Access login credentials
        String username = 'emilys';
        String password = 'emilyspass';

        /* DummyJSON_Secrets__c creds = DummyJSON_Secrets__c.getInstance();
        String username = creds.Username__c;
        String password = creds.Password__c; */

        //Post request to login to the server
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:DummyJson/auth/login');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setBody('{' +
            '"username": "' + username + '",' +
            '"password": "' + password +'",' +
            '"expiresInMins": 60' +
        '}');

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            LoginResponse login = (LoginResponse) JSON.deserialize(response.getBody(), LoginResponse.class);

            return login.token;
        } else {
            throw new CalloutException('Login failed: ' + response.getBody());
        }
    }
}