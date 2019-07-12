# MngIt

_A command line application for managing store inventory._

## Contributors

- Ben Braunstein (@MildlyConfused)

- Ian Grubb (@iangrubb)

## Installation

1. Fork / Clone this repository
2. Run a bundle install in your console to install the necessary gems

	```bash
	bundle install
	```

3. Set up [Mailgun-Ruby](https://github.com/mailgun/mailgun-ruby) by following the steps from their GitHub
4. Migrate the tables
	
	```bash
	rake db:migrate
	```

5. Write your own seed data or use rake to seed data with Faker

	```bash
        rake db:seed
        ```

6. Run our application

	```bash
        ruby bin/run.rb
        ```

## The Data Structure

The program uses the following domain models:

1. Sku -- Models the types of products that a store can purchase. Each Sku contains a brand, a name, a wholesale price, and an MSRP price.
2. Location -- Models specific store branches. Each Location contains a name, an address, and an email address.
3. Stock -- A join table (for Sku and Location) that keeps track of the instances of Sku items located at branches. Each Stock instance represents a specific item at a location. Each Stock contains a purchase price, which is set automatically based on the wholesale price of the Sku on Stock initialization.
4. SkuLocation -- A join table (for Sku and Location) that keeps track of how that location handles products of that Sku type. Each SkuLocation has a locations_price (what the location charges for items of that price) and a total sold counter (currently not functional, there for a future update). Sku locations are initialized concurrently with the initialization of Skus and Locations. This process ensures that there is exactly one SkuLocation for each pair of a Sku and a Location.
5. Purchase -- Models the entire purchase that a customer would make on a single occasion. Every purchase belongs to a Location.
6. PurchaseItem -- A join table (for Sku and Purchase) that keeps track of the instances of Sku items that belong to a purchase. Each PurchaseItem instance represents a specific item that someone purchased. Each PurchaseItem has a purchase_price, which is set automatically by the locations_price of the Sku for the location of purchase.

## The Command Line Interface

The application runs by creating CLI object and running a simple loop on that object. The object has instance variables that can be set in different ways to control the flow of the application.

User interaction is handled using the Action class. Any process of getting feedback from the user involves:

1. Giving the user some prompt.
2. Collecting and validating the users response.
3. Performing the appropriate action depending on the user response.

Whenever the program needs to perform these steps, a new action is created. Each action is initialized with:

1. ```prompt:``` -- a ```String``` to be initially displayed to the user.

2. ```error:``` -- a ```String``` to be displayed if the user's input is not validated.
3. ```validators:``` -- an ```Array``` of lambda expressions. Each takes one argument (the user's input) and returns a `Boolean`. The lambda expression that returns ```true``` validates the corresponding user input.
4. ```behaviors``` -- an ```Array``` of lambda expressions. The array should be the same length as the array stored in ```validators:```, and their elements correspond 1-1 (i.e. if the second validator returns ```true```, then the second behavior is called).

Just like real actions, members of the Action class are objects, but they only interact with the world (our program) as they are occuring. Actions automatically produce behavior upon initialization. Although they technically continue to exist after initialization, the program makes no use of them.

Besides providing a helpful device for abstracting content, the Action class gives the program's interface two valuable features. First, there are global validators and behaviors (like ```help```, which displays a general list of options) that can be called anywhere in the program, even if the local validators aren't expecting them. Second, whenever a user's input fails to satisfy an expected validator, an error message is displayed and the exact same action is performed again, allowing the user to seamlessly correct their input while staying at the same place in the function.

## Integration with Mailgun API

This application uses the Mailgun-Ruby API, which can be found at their GitHub: [MailGun-Ruby](https://github.com/mailgun/mailgun-ruby) in order to send email notifications automatically when import actions occur such as:

- Receipts for restocking goods
- Receipts when making sales
- Confirmations for transferring goods from one store to another
- Confirmations for reporting goods lost, stolen or damaged
- Alerts when a store has low stock on items.

In order to use the email system make sure you follow the instructions over at [MailGun-Ruby](https://github.com/mailgun/mailgun-ruby) to set up your environment.

To send an email you need to use the following syntax:

```ruby
Email.new(type_of_email, skus_hash, current_store)
```

Where the parameters are the following:

- type\_of_email is a string containing one of the following:
  - "buy_stock" when you want to send a restocking email
  - "low_stock" when you want to send a low stock alert email
  - "request\_from_store" when you want to send a goods transferred confirmation
  - "sale_made when you want to send an email after a purchase is made
- skus_hash is a hash with sku\_ids pointing to the quantity required for the transaction
- current_store is a Location instance where the action took place.

## That's it! Just one line of code to fire off emails.

If you need to edit the content of an email or create new email templates for your own personal needs that will happen in the Email model, where you will use a base template for the email body and input your information or variables to get the desired result.
