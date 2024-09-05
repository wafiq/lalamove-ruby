# spec/lalamove/client_spec.rb
# frozen_string_literal: true

require "spec_helper"
require "lalamove"

module Locations
  MARKET_DATA = {
    "MY" => {
      locations: [
        { name: "Amir bin Abdullah", address: "Mid Valley Megamall, Mid Valley City, 58000 Kuala Lumpur", lat: "3.118270", lng: "101.676720" },
        { name: "Tan Wei Ling", address: "Sunway Pyramid, 3, Jalan PJS 11/15, Bandar Sunway, 47500 Petaling Jaya", lat: "3.073210", lng: "101.607410" },
        { name: "Rajesh Kumar", address: "Pavilion KL, 168, Bukit Bintang Street, Bukit Bintang, 55100 Kuala Lumpur", lat: "3.148984", lng: "101.713302" },
        { name: "Nurul Huda binti Ismail", address: "1 Utama, 1, Lebuh Bandar Utama, Bandar Utama, 47800 Petaling Jaya", lat: "3.150281", lng: "101.615560" },
        { name: "Wong Mei Ling", address: "IOI City Mall, IOI Resort City, 62502 Putrajaya", lat: "2.969282", lng: "101.710136" }
      ],
      language: "en_MY"
    },
    "SG" => {
      locations: [
        { name: "Emily Wong", address: "VivoCity, 1 Harbourfront Walk, Singapore 098585", lat: "1.264012", lng: "103.822219" },
        { name: "Alex Lim", address: "ION Orchard, 2 Orchard Turn, Singapore 238801", lat: "1.304395", lng: "103.831857" },
        { name: "Grace Tan", address: "Jewel Changi Airport, 78 Airport Boulevard, Singapore 819666", lat: "1.360356", lng: "103.989296" },
        { name: "Ryan Ng", address: "Marina Bay Sands, 10 Bayfront Avenue, Singapore 018956", lat: "1.283844", lng: "103.860703" },
        { name: "Sophia Chen", address: "Suntec City, 3 Temasek Boulevard, Singapore 038983", lat: "1.293654", lng: "103.857134" }
      ],
      language: "en_SG"
    }
  }

  def self.random_locations(market)
    locations = MARKET_DATA[market][:locations].shuffle
    locations.first(2)
  end

  def self.random_phone(market)
    case market
    when "MY"
      "+601#{rand(10**8..10**9 - 1).to_s.rjust(8, "0")}"
    when "SG"
      "+65#{rand(10**8).to_s.rjust(8, "0")}"
    else
      raise ArgumentError, "Unsupported market: #{market}"
    end
  end

  def self.language_for_market(market)
    MARKET_DATA[market][:language]
  end
end

RSpec.describe Lalamove::Client, integration: true do
  let(:client) { @client }
  let(:quotation_response) { @quotation_response }
  let(:quotation_id) { @quotation_id }
  let(:order_id) { @order_id }

  before(:all) do
    market = "MY"
    locations = Locations.random_locations(market)

    @client = Lalamove::Client.new(ENV["LALAMOVE_API_KEY"], ENV["LALAMOVE_API_SECRET"], market, :sandbox)
    @quotation_details = {
      serviceType: "MOTORCYCLE",
      stops: [
        { coordinates: { lat: locations[0][:lat], lng: locations[0][:lng] }, address: locations[0][:address] },
        { coordinates: { lat: locations[1][:lat], lng: locations[1][:lng] }, address: locations[1][:address] }
      ],
      specialRequests: [],
      language: Locations.language_for_market(market)
    }

    # Get quotation
    @quotation_response = @client.get_quotation(@quotation_details)
    @quotation_id = @quotation_response["quotationId"]

    sender_id = @quotation_response["stops"][0]["stopId"]
    receiver_id = @quotation_response["stops"][1]["stopId"]

    # Create order
    order_details = {
      quotationId: @quotation_id,
      sender: { stopId: sender_id, name: locations[0][:name], phone: Locations.random_phone(market) },
      recipients: [
        { stopId: receiver_id, name: locations[1][:name], phone: Locations.random_phone(market), remarks: "Please call upon arrival" }
      ],
      isPODEnabled: true,
      partner: "Scanjer",
      metadata: {}
    }

    create_order_response = @client.create_order(order_details)
    @order_id = create_order_response["orderId"]
  end

  def wait_for_driver_assignment(timeout = 120, interval = 15)
    start_time = Time.now
    while Time.now - start_time < timeout
      order = client.get_order(order_id)
      return order["driverId"] if order["status"] == "ON_GOING"

      sleep interval
    end
    raise "Driver not assigned within #{timeout} seconds"
  end

  it "retrieves a quotation successfully" do
    expect(quotation_id).not_to be_nil
    expect(quotation_response).to be_a(Hash)
    expect(quotation_response["priceBreakdown"]).to be_a(Hash)
    expect(quotation_response["priceBreakdown"]["total"]).not_to be_nil
  end

  it "creates an order successfully" do
    expect(order_id).not_to be_nil
  end

  it "retrieves order details successfully" do
    response = client.get_order(order_id)
    expect(response["orderId"]).to eq(order_id)
    expect(response["status"]).not_to be_nil
  end

  it "adds a priority fee to the order successfully" do
    response = client.add_priority_fee(order_id, 10)
    expect(response["orderId"]).to eq(order_id)
    expect(response["priceBreakdown"]["priorityFee"].to_i).to eq(10)
  end

  it "retrieves driver details after assignment" do
    driver_id = wait_for_driver_assignment
    driver_details = client.get_driver_details(order_id, driver_id)
    expect(driver_details).to include("name", "phone")
  end

  it "cancels the order successfully" do
    response = client.cancel_order(order_id)
    expect(response.status).to eq(204)
  end
end
