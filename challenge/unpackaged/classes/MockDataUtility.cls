public class MockDataUtility {

    // Mock class for successful login
    public class MockSuccessLoginCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"token": "testToken123"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock class for failed login
    public class MockFailedLoginCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "Unauthorized"}');
            res.setStatusCode(401);
            return res;
        }
    }

    // Mock class for product sync response
    public class MockProductSyncCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(getProductSyncMockResponse());
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Method to get the mock product sync response as a JSON string
    public static String getProductSyncMockResponse() {
        return 
            '{' +
                '"products": [' +
                    '{' +
                        '"id": 1,' +
                        '"title": "Product 1",' +
                        '"description": "Description 1",' +
                        '"category": "Electronics",' +
                        '"price": 100.0,' +
                        '"discountPercentage": 10.0,' +
                        '"rating": 4.5,' +
                        '"stock": 10,' +
                        '"tags": ["tag1", "tag2"],' +
                        '"brand": "Brand A",' +
                        '"sku": "SKU1",' +
                        '"weight": 1.5,' +
                        '"dimensions": {"width": 10.0, "height": 5.0, "depth": 2.0},' +
                        '"warrantyInformation": "1 year",' +
                        '"shippingInformation": "Free shipping",' +
                        '"availabilityStatus": "In Stock",' +
                        '"reviews": [' +
                            '{' +
                                '"rating": 5,' +
                                '"comment": "Great product!",' +
                                '"reviewDate": "2023-04-01T00:00:00Z",' +
                                '"reviewerName": "John Doe",' +
                                '"reviewerEmail": "john.doe@example.com"' +
                            '}' +
                        '],' +
                        '"returnPolicy": "30 days",' +
                        '"minimumOrderQuantity": 1,' +
                        '"meta": {"barcode": "123456", "qrCode": "qrcode123"},' +
                        '"images": ["http://example.com/image1.jpg", "http://example.com/image2.jpg"],' +
                        '"thumbnail": "http://example.com/thumbnail.jpg"' +
                    '},' +
                    '{' +
                        '"id": 2,' +
                        '"title": "Product 2",' +
                        '"description": "Description 2",' +
                        '"category": "Books",' +
                        '"price": 20.0,' +
                        '"discountPercentage": 5.0,' +
                        '"rating": 3.5,' +
                        '"stock": 5,' +
                        '"tags": ["tag3", "tag4"],' +
                        '"brand": "Brand B",' +
                        '"sku": "SKU2",' +
                        '"weight": 0.8,' +
                        '"dimensions": {"width": 8.0, "height": 10.0, "depth": 1.5},' +
                        '"warrantyInformation": "6 months",' +
                        '"shippingInformation": "Paid shipping",' +
                        '"availabilityStatus": "Out of Stock",' +
                        '"reviews": [' +
                            '{' +
                                '"rating": 4,' +
                                '"comment": "Good book.",' +
                                '"reviewDate": "2023-03-30T00:00:00Z",' +
                                '"reviewerName": "Jane Smith",' +
                                '"reviewerEmail": "jane.smith@example.com"' +
                            '}' +
                        '],' +
                        '"returnPolicy": "15 days",' +
                        '"minimumOrderQuantity": 2,' +
                        '"meta": {"barcode": "654321", "qrCode": "qrcode456"},' +
                        '"images": ["http://example.com/image3.jpg"],' +
                        '"thumbnail": "http://example.com/thumbnail2.jpg"' +
                    '}' +
                ']' +
            '}';
    }

}