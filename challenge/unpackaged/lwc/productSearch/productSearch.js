import { track, wire, api, LightningElement } from 'lwc';
import syncProducts from '@salesforce/apex/productSyncController.syncProducts';
import getEligibleProductIds from '@salesforce/apex/productQueryController.getEligibleProductIds';
import getProducts from '@salesforce/apex/productQueryController.getProducts';
import getFilterPicklistValues from '@salesforce/apex/productQueryController.getFilterPicklistValues';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ProductSearch extends LightningElement {
    @track pageNumber = 1;
    @track isLastPage = false;
    @track isFirstPage = true;
    @track isLoading;
    @track products = [];
    @track totalProducts;
    totalPages
    limitSize = 20;
    productsInStock;
    productsInView;
    brandOptions = [];
    categoryOptions = [];
    eligibleProductIds = [];
    ratingOptions = [
        { label: 'Any Rating', value: null },
        { label: 'Over 3 ⭐⭐⭐', value: '3' },
        { label: 'Over 4 ⭐⭐⭐⭐', value: '4' }
        ];
    filters = {
        productName: '',
        brand: '',
        minPrice: null,
        maxPrice: null,
        minRating: null,
        category: ''
    };

    // Calculates the number of records to skip based on current page
    get offsetSize() {
        return (this.pageNumber - 1) * this.limitSize;
    }

    async connectedCallback() {
        this.isLoading = true;
        try {
            await syncProducts();
            const data = await getFilterPicklistValues();
            this.brandOptions = data.brands.map(b => ({ label: b, value: b }));
            this.brandOptions.unshift({ label: 'None', value: '' })
            this.categoryOptions = data.categories.map(c => ({ label: c, value: c }));
            this.categoryOptions.unshift({ label: 'None', value: '' })
            await this.loadProducts();
        } catch (error) {
            console.error('Initialization error:', error);
            this.dispatchEvent(new ShowToastEvent({     
                title: 'Initialization Error',
                message: 'There was a problem loading product data.',
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    // Loads products from Apex using filters, pagination, and eligibility
    async loadProducts() {
        try {
            this.eligibleProductIds = await getEligibleProductIds()
            const result = await getProducts({
                limitSize: this.limitSize,
                offsetSize: this.offsetSize,
                filtersJson: JSON.stringify(this.filters),
                eligibleProductIds: this.eligibleProductIds
            });
            this.products = result.products;
            this.productsInView = result.products.length;
            this.productsInStock = result.productsInStock;
            this.totalProducts = result.totalCount;
            this.totalPages
            this.isFirstPage = this.pageNumber === 1;
            this.isLastPage = (this.pageNumber * this.limitSize) >= this.totalProducts;
            let pageCount = Math.ceil(this.totalProducts / this.limitSize);
            pageCount < 1 ? this.totalPages = 1 : this.totalPages = pageCount;;
        } catch (error) {
            console.error('Error loading products:', error);
        }
    }

    // Updates the filter values based on user input
    handleFilterChange(event) {
        const field = event.target.dataset.field;
        let value = event.target.value;
        if ((field === 'maxPrice' || field === 'minPrice') && value === '') {
            value = null;
            }
        this.filters[field] = value;
    }

    // Initiates a new search with the current filters and resets to page 1
    searchProducts() {
        this.pageNumber = 1;
        this.loadProducts();
    }

    // Advances to the next page of products if not on the last page
    handleNext() {
        if (!this.isLastPage) {
            this.pageNumber++;
            this.loadProducts();
        }
    }

    // Goes back to the previous page of products if not on the first page
    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadProducts();
        }
    }


}