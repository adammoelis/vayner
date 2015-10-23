require 'pry'
require 'csv'
require 'json'

class Assignment

  attr_accessor :campaign_array, :dictionary, :type_dictionary

  ACTIONS_TO_COUNT = ["x", "y"]

  def initialize
    @campaign_array = []
    @dictionary = {initiatives: [], audiences: [], assets: []}
    @type_dictionary = {}
  end

  def read_file(file_name)
    CSV.foreach(file_name) do |campaign_row|
      @campaign_array << convert_to_hash(campaign_row)
    end
    @campaign_array = @campaign_array.compact
  end

  def populate_dictionary(campaign_details)
      @dictionary[:initiatives] << campaign_details[0] unless @dictionary[:initiatives].include?(campaign_details[0])
      @dictionary[:audiences] << campaign_details[1] unless @dictionary[:audiences].include?(campaign_details[1])
      @dictionary[:assets] << campaign_details[2] unless @dictionary[:assets].include?(campaign_details[2])
  end

  def read_file_random_order(file_name)
    CSV.foreach(file_name) do |campaign_row|
      campaign = convert_to_right_order(campaign_row)
      @type_dictionary[campaign] = campaign_row[1]
    end
  end

  def convert_to_right_order(campaign_row)
    campaign_details = campaign_row[0].split("_")
    array = campaign_details.each_with_object([]) do |type_of_campaign, array|
      if dictionary[:initiatives].include?(type_of_campaign)
        array[0] = type_of_campaign
      elsif dictionary[:audiences].include?(type_of_campaign)
        array[1] = type_of_campaign
      elsif dictionary[:assets].include?(type_of_campaign)
        array[2] = type_of_campaign
      end
    end
    array.join("_")
  end

  def add_type_to_campaign_array
    campaign_array.each do |campaign|
      campaign[:type] = type_dictionary[campaign[:campaign]] if type_dictionary[campaign[:campaign]]
    end
  end

  def run
    read_file('source1.csv')
    read_file_random_order('source2.csv')
    add_type_to_campaign_array
    unique_feb_campaigns = filter_duplicate_campaigns(campaigns_run_in(2))
    puts "The number of unique campaigns in February is #{unique_feb_campaigns.size}"
    conversions_for_plants = conversions_for('plants')
    puts "The number of conversions for plants is #{conversions_for_plants}"
    least_expensive = least_expensive_in_hash(audience_asset_combinations)
    puts "The lease expensive audience_asset combination is #{least_expensive[0][0]}"
    puts "The total cost per video view is $#{cost_per_video_view}"
  end

  def convert_to_hash(campaign_row)
    campaign_details = campaign_row[0].split("_")
    populate_dictionary(campaign_details)
    if valid_json?(campaign_row[4])
      {campaign: campaign_row[0],
        initative: campaign_details[0],
        audience: campaign_details[1],
        asset: campaign_details[2],
        audience_asset: campaign_details[1] + "_" + campaign_details[2],
        date: Date.parse(campaign_row[1]),
        spend: campaign_row[2],
        impressions: campaign_row[3],
        actions: JSON.parse(campaign_row[4])
      }

    end
  end

  def valid_json?(json)
    begin
      JSON.parse(json)
      return true
    rescue Exception => e
      return false
    end
  end

  def filter_duplicate_campaigns(array_of_campaign_hashes)
    array_of_campaign_hashes.uniq { |campaign| campaign[:campaign] }
  end

  def campaigns_run_in(month_num)
    campaign_array.select{|campaign| campaign[:date].month == month_num}
  end

  def campaigns_for(initiative_type)
    campaign_array.select{|campaign| campaign[:initative] == initiative_type}
  end

  def conversions_for(initiative_type)
    conversions_sum = 0
    campaigns_for(initiative_type).each do |campaign|
      campaign[:actions].each do |action|
        if action["action"] == 'conversions'
          num_of_conversions = action.select {|k, v| ACTIONS_TO_COUNT.include?(k)}.values.first
          conversions_sum += num_of_conversions if num_of_conversions
        end
      end
    end
    conversions_sum
  end

  def audience_asset_combinations
    audience_asset_combo_hash = campaign_array.each_with_object({}) do |campaign, audience_asset_combo_hash|
      if audience_asset_combo_hash.keys.include?(campaign[:audience_asset])
        audience_asset_combo_hash[campaign[:audience_asset]][:spend] += campaign[:spend].to_f
        audience_asset_combo_hash[campaign[:audience_asset]][:conversions] += conversions_for_row(campaign)
      else
        audience_asset_combo_hash[campaign[:audience_asset]] = {spend: campaign[:spend].to_f, conversions: conversions_for_row(campaign)}
      end
    end
  end

  def conversions_for_row(campaign_row)
    conversions_sum = 0
    campaign_row[:actions].each do |action|
      if action["action"] == 'conversions'
        num_of_conversions = action.select {|k, v| ACTIONS_TO_COUNT.include?(k)}.values.first
        conversions_sum += num_of_conversions if num_of_conversions
      end
    end
    conversions_sum
  end

  def least_expensive_in_hash(audience_asset_combo_hash)
    audience_asset_combo_hash.sort_by{|k,v| v[:spend]/v[:conversions]}
  end

  def cost_per_video_view
    total_cost = 0
    total_view_count = 0
    campaign_array.each do |campaign|
      if campaign[:type] == 'video'
        total_cost += campaign[:spend].to_i
        campaign[:actions].each do |action|
          if action['action'] == 'views'
            views = action.select {|k, v| ACTIONS_TO_COUNT.include?(k)}.values.first
            total_view_count += views.to_i
          end
        end
      end
    end
    sprintf('%.2f', total_cost/total_view_count.to_f)
  end

end


a = Assignment.new
a.run
