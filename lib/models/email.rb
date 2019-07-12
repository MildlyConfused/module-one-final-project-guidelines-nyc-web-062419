class Email
  attr_reader :sku, :quantity, :current_store, :total, :subject

  def initialize(subject, sku_hash, current_store)
    @current_store = current_store
    @sku_hash = sku_hash
    @total = 0.0
    case subject
    when "buy_stock"
      @body = purchase_goods_body_builder(sku_hash)
      @subject = "Your restocking reciept of #{total}"
      self.send_simple_message(@subject, @body)
    when "low_stock"
      #Email stuff for low stock item
      @body = low_stock_body_builder(sku_hash)
      @subject = "You have low stock"
      self.send_simple_message(@subject, @body)
    when "request_from_store"
      #Email stuff for request item from another store
      @body = request_body_builder(sku_hash)
      @subject = "Thank you for transferring goods to #{current_store.name} at #{current_store.address}"
      self.send_simple_message(@subject, @body)
    when "sale_made"
      #Email stuff for a sale
      @body = sale_made_body_builder(sku_hash)
      @subject = "Reciept of your sale for #{total}"
      self.send_simple_message(@subject, @body)
    else
    end
  end

  def send_simple_message(subject, body)
    # First, instantiate the Mailgun Client with your API key
    mg_client = Mailgun::Client.new ENV["API_KEY"]
    # Define your message parameters
    message_params = { from: "ManageIt@gmail.com",
                       to: "benzbraunstein@gmail.com",
                       subject: subject,
                       html: body }
    # Send your message through the client
    mg_client.send_message ENV["API_SANDBOX_DOMAIN"], message_params
  end

  def request_body_builder(sku_hash)
    all_rows = ""
    sku_hash.each do |sku_id, quantity|
      price = Sku.find(sku_id).wholesale_price
      @total += price * quantity
      new_row = Email.item_row_template.call(Sku.find(sku_id), quantity, price, self.current_store)
      all_rows += new_row
    end
    @total = @total.round(2)
    full_tbody = Email.tbody_template.call(all_rows, total)
    Email.request_goods_template.call(full_tbody, current_store, total)
  end

  def purchase_goods_body_builder(sku_hash)
    all_rows = ""
    sku_hash.each do |sku_id, quantity|
      price = Sku.find(sku_id).wholesale_price
      #To get the location's price use this sku_locations.find { |sku_location| sku_location.location == self.current_store }.locations_price
      @total += price * quantity
      new_row = Email.item_row_template.call(Sku.find(sku_id), quantity, price, self.current_store)
      all_rows += new_row
    end
    @total = @total.round(2)
    full_tbody = Email.tbody_template.call(all_rows, total)
    Email.purchased_goods_template.call(full_tbody, current_store, total)
  end

  def low_stock_body_builder(sku_hash)
    all_rows = ""
    sku_hash.each do |sku_id, quantity|
      new_row = Email.low_stock_row_template.call(Sku.find(sku_id), quantity)
      all_rows += new_row
    end
    @total = @total.round(2)
    Email.low_stock_template.call(all_rows, current_store)
  end

  def sale_made_body_builder(sku_hash)
    all_rows = ""
    sku_hash.each do |sku_id, quantity|
      price = Sku.find(sku_id).sku_locations.find { |sku_location| sku_location.location == self.current_store }.locations_price
      @total += price * quantity
      new_row = Email.item_row_template.call(Sku.find(sku_id), quantity, price, self.current_store)
      all_rows += new_row
    end
    @total = @total.round(2)
    full_tbody = Email.tbody_template.call(all_rows, total)
    Email.sale_made_template.call(full_tbody, current_store, total)
  end

  #Getters for all the class variable strings
  def self.request_goods_template
    @@request_goods_template
  end

  def self.low_stock_row_template
    @@low_stock_row_template
  end

  def self.tbody_template
    @@tbody_template
  end

  def self.sale_made_template
    @@sale_made_template
  end

  def self.item_row_template
    @@item_row_template
  end
  
  def self.purchased_goods_template
    @@purchased_goods_template
  end

  def self.low_stock_template
    @@low_stock_template
  end

  #Partial templates
  @@item_row_template = lambda { |sku, quantity, price, current_store|
    "
      <tr
    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
  >
    <td
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; border-top-width: 1px; border-top-color: #eee; border-top-style: solid; margin: 0; padding: 5px 0;\"
      valign=\"top\"
    >
      #{quantity}x #{sku.fullname}
    </td>
    <td
      class=\"alignright\"
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: right; border-top-width: 1px; border-top-color: #eee; border-top-style: solid; margin: 0; padding: 5px 0;\"
      align=\"right\"
      valign=\"top\"
    >
      $ #{price}/unit
    </td>
  </tr>
    "
  }
  @@low_stock_row_template = lambda { |sku, quantity|
    "
      <tr
    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
  >
    <td
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; border-top-width: 1px; border-top-color: #eee; border-top-style: solid; margin: 0; padding: 5px 0;\"
      valign=\"top\"
    >
      #{sku.fullname}
    </td>
    <td
      class=\"alignright\"
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: right; border-top-width: 1px; border-top-color: #eee; border-top-style: solid; margin: 0; padding: 5px 0;\"
      align=\"right\"
      valign=\"top\"
    >
      #{quantity} left
    </td>
  </tr>
    "
  }

  @@tbody_template = lambda { |all_rows, total|
    "<tbody>
  #{all_rows}
  <tr
    class=\"total\"
    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
  >
    <td
      class=\"alignright\"
      width=\"80%\"
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: right; border-top-width: 2px; border-top-color: #333; border-top-style: solid; border-bottom-color: #333; border-bottom-width: 2px; border-bottom-style: solid; font-weight: 700; margin: 0; padding: 5px 0;\"
      align=\"right\"
      valign=\"top\"
    >
      Total
    </td>
    <td
      class=\"alignright\"
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: right; border-top-width: 2px; border-top-color: #333; border-top-style: solid; border-bottom-color: #333; border-bottom-width: 2px; border-bottom-style: solid; font-weight: 700; margin: 0; padding: 5px 0;\"
      align=\"right\"
      valign=\"top\"
    >
      $ #{total}
    </td>
  </tr>
</tbody>"
  }

  #All Full Templates
  @@sale_made_template = lambda { |tbody, current_store, total|
    "<!DOCTYPE html>
<html
  style=\"font-family: \'Helvetica Neue\', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
>
  <head>
    <meta name=\"viewport\" content=\"width=device-width\" />
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
    <title>Billing e.g. invoices and receipts</title>

    <style type=\"text/css\">
      img {
        max-width: 100%;
      }

      body {
        -webkit-font-smoothing: antialiased;
        -webkit-text-size-adjust: none;
        width: 100% !important;
        height: 100%;
        line-height: 1.6em;
      }

      body {
        background-color: #f6f6f6;
      }

      @media only screen and (max-width: 640px) {
        body {
          padding: 0 !important;
        }

        h1 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h2 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h3 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h4 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h1 {
          font-size: 22px !important;
        }

        h2 {
          font-size: 18px !important;
        }

        h3 {
          font-size: 16px !important;
        }

        .container {
          padding: 0 !important;
          width: 100% !important;
        }

        .content {
          padding: 0 !important;
        }

        .content-wrap {
          padding: 10px !important;
        }

        .invoice {
          width: 100% !important;
        }
      }
    </style>
  </head>

  <body
    itemscope
    itemtype=\"http://schema.org/EmailMessage\"
    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; -webkit-font-smoothing: antialiased; -webkit-text-size-adjust: none; width: 100% !important; height: 100%; line-height: 1.6em; background-color: #f6f6f6; margin: 0;\"
    bgcolor=\"#f6f6f6\"
  >
    <table
      class=\"body-wrap\"
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; background-color: #f6f6f6; margin: 0;\"
      bgcolor=\"#f6f6f6\"
    >
      <tr
        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
      >
        <td
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;\"
          valign=\"top\"
        ></td>
        <td
          class=\"container\"
          width=\"600\"
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; display: block !important; max-width: 600px !important; clear: both !important; margin: 0 auto;\"
          valign=\"top\"
        >
          <div
            class=\"content\"
            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; max-width: 600px; display: block; margin: 0 auto; padding: 20px;\"
          >
            <table
              class=\"main\"
              width=\"100%\"
              cellpadding=\"0\"
              cellspacing=\"0\"
              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; border-radius: 3px; background-color: #fff; margin: 0; border: 1px solid #e9e9e9;\"
              bgcolor=\"#fff\"
            >
              <tr
                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
              >
                <td
                  class=\"content-wrap aligncenter\"
                  style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 20px;\"
                  align=\"center\"
                  valign=\"top\"
                >
                  <table
                    width=\"100%\"
                    cellpadding=\"0\"
                    cellspacing=\"0\"
                    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                  >
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;\"
                        valign=\"top\"
                      >
                        <h1
                          class=\"aligncenter\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,\'Lucida Grande\',sans-serif; box-sizing: border-box; font-size: 32px; color: #000; line-height: 1.2em; font-weight: 500; text-align: center; margin: 40px 0 0;\"
                          align=\"center\"
                        >
                          $ #{total} Received
                        </h1>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;\"
                        valign=\"top\"
                      >
                        <h2
                          class=\"aligncenter\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,\'Lucida Grande\',sans-serif; box-sizing: border-box; font-size: 24px; color: #000; line-height: 1.2em; font-weight: 400; text-align: center; margin: 40px 0 0;\"
                          align=\"center\"
                        >
                          Your sale is now completed.
                        </h2>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        <table
                          class=\"invoice\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; text-align: left; width: 80%; margin: 40px auto;\"
                        >
                          <tr
                            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                          >
                            <td
                              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 5px 0;\"
                              valign=\"top\"
                            >
                              Sale Completed at:<br
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                              />#{current_store.name}<br
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                              />#{current_store.address}
                            </td>
                          </tr>
                          <tr
                            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                          >
                            <td
                              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 5px 0;\"
                              valign=\"top\"
                            >
                              <table
                                class=\"invoice-items\"
                                cellpadding=\"0\"
                                cellspacing=\"0\"
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; margin: 0;\"
                              >
                                #{tbody}
                              </table>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        <a
                          href=\"http://www.mailgun.com\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; color: #348eda; text-decoration: underline; margin: 0;\"
                          >View in browser</a
                        >
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        Order Completed on #{Time.now.ctime}
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

            <div
              class=\"footer\"
              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; clear: both; color: #999; margin: 0; padding: 20px;\"
            >
              <table
                width=\"100%\"
                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
              >
                <tr
                  style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                >
                  <td
                    class=\"aligncenter content-block\"
                    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 12px; vertical-align: top; color: #999; text-align: center; margin: 0; padding: 0 0 20px;\"
                    align=\"center\"
                    valign=\"top\"
                  >
                    Questions? Email
                    <a
                      href=\"mailto:\"
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 12px; color: #999; text-decoration: underline; margin: 0;\"
                      >support@ManageIt.com</a
                    >
                  </td>
                </tr>
              </table>
            </div>
          </div>
        </td>
        <td
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;\"
          valign=\"top\"
        ></td>
      </tr>
    </table>
  </body>
</html>
"
  }

  @@purchased_goods_template = lambda { |tbody, current_store, total|
    "<!DOCTYPE html>
<html
  style=\"font-family: \'Helvetica Neue\', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
>
  <head>
    <meta name=\"viewport\" content=\"width=device-width\" />
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
    <title>Billing e.g. invoices and receipts</title>

    <style type=\"text/css\">
      img {
        max-width: 100%;
      }

      body {
        -webkit-font-smoothing: antialiased;
        -webkit-text-size-adjust: none;
        width: 100% !important;
        height: 100%;
        line-height: 1.6em;
      }

      body {
        background-color: #f6f6f6;
      }

      @media only screen and (max-width: 640px) {
        body {
          padding: 0 !important;
        }

        h1 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h2 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h3 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h4 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h1 {
          font-size: 22px !important;
        }

        h2 {
          font-size: 18px !important;
        }

        h3 {
          font-size: 16px !important;
        }

        .container {
          padding: 0 !important;
          width: 100% !important;
        }

        .content {
          padding: 0 !important;
        }

        .content-wrap {
          padding: 10px !important;
        }

        .invoice {
          width: 100% !important;
        }
      }
    </style>
  </head>

  <body
    itemscope
    itemtype=\"http://schema.org/EmailMessage\"
    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; -webkit-font-smoothing: antialiased; -webkit-text-size-adjust: none; width: 100% !important; height: 100%; line-height: 1.6em; background-color: #f6f6f6; margin: 0;\"
    bgcolor=\"#f6f6f6\"
  >
    <table
      class=\"body-wrap\"
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; background-color: #f6f6f6; margin: 0;\"
      bgcolor=\"#f6f6f6\"
    >
      <tr
        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
      >
        <td
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;\"
          valign=\"top\"
        ></td>
        <td
          class=\"container\"
          width=\"600\"
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; display: block !important; max-width: 600px !important; clear: both !important; margin: 0 auto;\"
          valign=\"top\"
        >
          <div
            class=\"content\"
            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; max-width: 600px; display: block; margin: 0 auto; padding: 20px;\"
          >
            <table
              class=\"main\"
              width=\"100%\"
              cellpadding=\"0\"
              cellspacing=\"0\"
              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; border-radius: 3px; background-color: #fff; margin: 0; border: 1px solid #e9e9e9;\"
              bgcolor=\"#fff\"
            >
              <tr
                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
              >
                <td
                  class=\"content-wrap aligncenter\"
                  style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 20px;\"
                  align=\"center\"
                  valign=\"top\"
                >
                  <table
                    width=\"100%\"
                    cellpadding=\"0\"
                    cellspacing=\"0\"
                    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                  >
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;\"
                        valign=\"top\"
                      >
                        <h1
                          class=\"aligncenter\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,\'Lucida Grande\',sans-serif; box-sizing: border-box; font-size: 32px; color: #000; line-height: 1.2em; font-weight: 500; text-align: center; margin: 40px 0 0;\"
                          align=\"center\"
                        >
                          $ #{total} Paid
                        </h1>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;\"
                        valign=\"top\"
                      >
                        <h2
                          class=\"aligncenter\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,\'Lucida Grande\',sans-serif; box-sizing: border-box; font-size: 24px; color: #000; line-height: 1.2em; font-weight: 400; text-align: center; margin: 40px 0 0;\"
                          align=\"center\"
                        >
                          Your restocking has been confirmed.
                        </h2>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        <table
                          class=\"invoice\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; text-align: left; width: 80%; margin: 40px auto;\"
                        >
                          <tr
                            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                          >
                            <td
                              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 5px 0;\"
                              valign=\"top\"
                            >
                              Billed to:<br
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                              />#{current_store.name}<br
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                              />#{current_store.address}
                            </td>
                          </tr>
                          <tr
                            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                          >
                            <td
                              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 5px 0;\"
                              valign=\"top\"
                            >
                              <table
                                class=\"invoice-items\"
                                cellpadding=\"0\"
                                cellspacing=\"0\"
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; margin: 0;\"
                              >
                                #{tbody}
                              </table>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        <a
                          href=\"http://www.mailgun.com\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; color: #348eda; text-decoration: underline; margin: 0;\"
                          >View in browser</a
                        >
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        Order Completed on #{Time.now.ctime}
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

            <div
              class=\"footer\"
              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; clear: both; color: #999; margin: 0; padding: 20px;\"
            >
              <table
                width=\"100%\"
                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
              >
                <tr
                  style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                >
                  <td
                    class=\"aligncenter content-block\"
                    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 12px; vertical-align: top; color: #999; text-align: center; margin: 0; padding: 0 0 20px;\"
                    align=\"center\"
                    valign=\"top\"
                  >
                    Questions? Email
                    <a
                      href=\"mailto:\"
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 12px; color: #999; text-decoration: underline; margin: 0;\"
                      >support@ManageIt.com</a
                    >
                  </td>
                </tr>
              </table>
            </div>
          </div>
        </td>
        <td
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;\"
          valign=\"top\"
        ></td>
      </tr>
    </table>
  </body>
</html>
"
  }

  @@low_stock_template = lambda { |tbody, current_store|
    "<!DOCTYPE html>
<html
  style=\"font-family: \'Helvetica Neue\', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
>
  <head>
    <meta name=\"viewport\" content=\"width=device-width\" />
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
    <title>Billing e.g. invoices and receipts</title>

    <style type=\"text/css\">
      img {
        max-width: 100%;
      }

      body {
        -webkit-font-smoothing: antialiased;
        -webkit-text-size-adjust: none;
        width: 100% !important;
        height: 100%;
        line-height: 1.6em;
      }

      body {
        background-color: #f6f6f6;
      }

      @media only screen and (max-width: 640px) {
        body {
          padding: 0 !important;
        }

        h1 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h2 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h3 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h4 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h1 {
          font-size: 22px !important;
        }

        h2 {
          font-size: 18px !important;
        }

        h3 {
          font-size: 16px !important;
        }

        .container {
          padding: 0 !important;
          width: 100% !important;
        }

        .content {
          padding: 0 !important;
        }

        .content-wrap {
          padding: 10px !important;
        }

        .invoice {
          width: 100% !important;
        }
      }
    </style>
  </head>

  <body
    itemscope
    itemtype=\"http://schema.org/EmailMessage\"
    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; -webkit-font-smoothing: antialiased; -webkit-text-size-adjust: none; width: 100% !important; height: 100%; line-height: 1.6em; background-color: #f6f6f6; margin: 0;\"
    bgcolor=\"#f6f6f6\"
  >
    <table
      class=\"body-wrap\"
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; background-color: #f6f6f6; margin: 0;\"
      bgcolor=\"#f6f6f6\"
    >
      <tr
        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
      >
        <td
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;\"
          valign=\"top\"
        ></td>
        <td
          class=\"container\"
          width=\"600\"
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; display: block !important; max-width: 600px !important; clear: both !important; margin: 0 auto;\"
          valign=\"top\"
        >
          <div
            class=\"content\"
            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; max-width: 600px; display: block; margin: 0 auto; padding: 20px;\"
          >
            <table
              class=\"main\"
              width=\"100%\"
              cellpadding=\"0\"
              cellspacing=\"0\"
              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; border-radius: 3px; background-color: #fff; margin: 0; border: 1px solid #e9e9e9;\"
              bgcolor=\"#fff\"
            >
              <tr
                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
              >
                <td
                  class=\"content-wrap aligncenter\"
                  style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 20px;\"
                  align=\"center\"
                  valign=\"top\"
                >
                  <table
                    width=\"100%\"
                    cellpadding=\"0\"
                    cellspacing=\"0\"
                    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                  >
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;\"
                        valign=\"top\"
                      >
                        <h1
                          class=\"aligncenter\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,\'Lucida Grande\',sans-serif; box-sizing: border-box; font-size: 32px; color: #000; line-height: 1.2em; font-weight: 500; text-align: center; margin: 40px 0 0;\"
                          align=\"center\"
                        >
                          Attention #{current_store.name} at #{current_store.address}
                        </h1>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;\"
                        valign=\"top\"
                      >
                        <h2
                          class=\"aligncenter\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,\'Lucida Grande\',sans-serif; box-sizing: border-box; font-size: 24px; color: #000; line-height: 1.2em; font-weight: 400; text-align: center; margin: 40px 0 0;\"
                          align=\"center\"
                        >
                          You have low stock for the following items:
                        </h2>
                      </td>
                    </tr>
                          <tr
                            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                          >
                            <td
                              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 5px 0;\"
                              valign=\"top\"
                            >
                              <table
                                class=\"invoice-items\"
                                cellpadding=\"0\"
                                cellspacing=\"0\"
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; margin: 0;\"
                              >
                                #{tbody}
                              </table>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        <a
                          href=\"http://www.mailgun.com\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; color: #348eda; text-decoration: underline; margin: 0;\"
                          >View in browser</a
                        >
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        This message was created at #{Time.now.ctime}
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

            <div
              class=\"footer\"
              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; clear: both; color: #999; margin: 0; padding: 20px;\"
            >
              <table
                width=\"100%\"
                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
              >
                <tr
                  style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                >
                  <td
                    class=\"aligncenter content-block\"
                    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 12px; vertical-align: top; color: #999; text-align: center; margin: 0; padding: 0 0 20px;\"
                    align=\"center\"
                    valign=\"top\"
                  >
                    Questions? Email
                    <a
                      href=\"mailto:\"
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 12px; color: #999; text-decoration: underline; margin: 0;\"
                      >support@ManageIt.com</a
                    >
                  </td>
                </tr>
              </table>
            </div>
          </div>
        </td>
        <td
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;\"
          valign=\"top\"
        ></td>
      </tr>
    </table>
  </body>
</html>"
  }

  @@request_goods_template = lambda { |tbody, current_store, total|
  "<!DOCTYPE html>
<html
  style=\"font-family: \'Helvetica Neue\', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
>
  <head>
    <meta name=\"viewport\" content=\"width=device-width\" />
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
    <title>Billing e.g. invoices and receipts</title>

    <style type=\"text/css\">
      img {
        max-width: 100%;
      }

      body {
        -webkit-font-smoothing: antialiased;
        -webkit-text-size-adjust: none;
        width: 100% !important;
        height: 100%;
        line-height: 1.6em;
      }

      body {
        background-color: #f6f6f6;
      }

      @media only screen and (max-width: 640px) {
        body {
          padding: 0 !important;
        }

        h1 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h2 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h3 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h4 {
          font-weight: 800 !important;
          margin: 20px 0 5px !important;
        }

        h1 {
          font-size: 22px !important;
        }

        h2 {
          font-size: 18px !important;
        }

        h3 {
          font-size: 16px !important;
        }

        .container {
          padding: 0 !important;
          width: 100% !important;
        }

        .content {
          padding: 0 !important;
        }

        .content-wrap {
          padding: 10px !important;
        }

        .invoice {
          width: 100% !important;
        }
      }
    </style>
  </head>

  <body
    itemscope
    itemtype=\"http://schema.org/EmailMessage\"
    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; -webkit-font-smoothing: antialiased; -webkit-text-size-adjust: none; width: 100% !important; height: 100%; line-height: 1.6em; background-color: #f6f6f6; margin: 0;\"
    bgcolor=\"#f6f6f6\"
  >
    <table
      class=\"body-wrap\"
      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; background-color: #f6f6f6; margin: 0;\"
      bgcolor=\"#f6f6f6\"
    >
      <tr
        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
      >
        <td
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;\"
          valign=\"top\"
        ></td>
        <td
          class=\"container\"
          width=\"600\"
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; display: block !important; max-width: 600px !important; clear: both !important; margin: 0 auto;\"
          valign=\"top\"
        >
          <div
            class=\"content\"
            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; max-width: 600px; display: block; margin: 0 auto; padding: 20px;\"
          >
            <table
              class=\"main\"
              width=\"100%\"
              cellpadding=\"0\"
              cellspacing=\"0\"
              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; border-radius: 3px; background-color: #fff; margin: 0; border: 1px solid #e9e9e9;\"
              bgcolor=\"#fff\"
            >
              <tr
                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
              >
                <td
                  class=\"content-wrap aligncenter\"
                  style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 20px;\"
                  align=\"center\"
                  valign=\"top\"
                >
                  <table
                    width=\"100%\"
                    cellpadding=\"0\"
                    cellspacing=\"0\"
                    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                  >
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;\"
                        valign=\"top\"
                      >
                        <h1
                          class=\"aligncenter\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,\'Lucida Grande\',sans-serif; box-sizing: border-box; font-size: 32px; color: #000; line-height: 1.2em; font-weight: 500; text-align: center; margin: 40px 0 0;\"
                          align=\"center\"
                        >
                          $ #{total} Transferred
                        </h1>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;\"
                        valign=\"top\"
                      >
                        <h2
                          class=\"aligncenter\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,\'Lucida Grande\',sans-serif; box-sizing: border-box; font-size: 24px; color: #000; line-height: 1.2em; font-weight: 400; text-align: center; margin: 40px 0 0;\"
                          align=\"center\"
                        >
                          You transferred goods to #{current_store.name} at #{current_store.address}
                        </h2>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        <table
                          class=\"invoice\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; text-align: left; width: 80%; margin: 40px auto;\"
                        >
                          <tr
                            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                          >
                            <td
                              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 5px 0;\"
                              valign=\"top\"
                            >
                              Transferred to:<br
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                              />#{current_store.name}<br
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                              />#{current_store.address}
                            </td>
                          </tr>
                          <tr
                            style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                          >
                            <td
                              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 5px 0;\"
                              valign=\"top\"
                            >
                              <table
                                class=\"invoice-items\"
                                cellpadding=\"0\"
                                cellspacing=\"0\"
                                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; margin: 0;\"
                              >
                                #{tbody}
                              </table>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        <a
                          href=\"http://www.mailgun.com\"
                          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; color: #348eda; text-decoration: underline; margin: 0;\"
                          >View in browser</a
                        >
                      </td>
                    </tr>
                    <tr
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                    >
                      <td
                        class=\"content-block aligncenter\"
                        style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; text-align: center; margin: 0; padding: 0 0 20px;\"
                        align=\"center\"
                        valign=\"top\"
                      >
                        Transfer Completed on #{Time.now.ctime}
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

            <div
              class=\"footer\"
              style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; clear: both; color: #999; margin: 0; padding: 20px;\"
            >
              <table
                width=\"100%\"
                style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
              >
                <tr
                  style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;\"
                >
                  <td
                    class=\"aligncenter content-block\"
                    style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 12px; vertical-align: top; color: #999; text-align: center; margin: 0; padding: 0 0 20px;\"
                    align=\"center\"
                    valign=\"top\"
                  >
                    Questions? Email
                    <a
                      href=\"mailto:\"
                      style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 12px; color: #999; text-decoration: underline; margin: 0;\"
                      >support@ManageIt.com</a
                    >
                  </td>
                </tr>
              </table>
            </div>
          </div>
        </td>
        <td
          style=\"font-family: \'Helvetica Neue\',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0;\"
          valign=\"top\"
        ></td>
      </tr>
    </table>
  </body>
</html>
"
}
end
