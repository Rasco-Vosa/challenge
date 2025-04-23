import {track, api, LightningElement } from 'lwc';

export default class ProductTile extends LightningElement {
    @api name;
    @api brand;
    @api category;
    @api price;
    @api rating;
    @api image;
}