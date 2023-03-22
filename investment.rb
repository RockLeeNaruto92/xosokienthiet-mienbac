require 'csv'
require "./log"
require "nokogiri"
require "pry"

class InvestmentResult
  INPUT_CSV_FILE = "./investment.csv"
  OUTPUT_CSV_FILE = "./investment_output.csv"

  URL = "https://xoso.mobi/kqxs-:date-ket-qua-xo-so-ngay-:date.html"

  def self.process
    grouped_by_date = read_input_csv
    output_csv = []

    grouped_by_date.each do |key, val|
      date = Date.parse(key)
      day = date.strftime("%d").gsub("0", "")
      month = date.strftime("%m").gsub("0", "")
      year = date.strftime("%Y")
      date_str = "#{day}-#{month}-#{year}"
      Log.info "Date: #{date_str}"

      url = URL.gsub ":date", date_str

      result = get_result url
      Log.info "\t\t##{result}"

      val.each do |row|
        row_result = process_for_a_row row, result
        output_csv << row_result
      end
    end

    File.open(OUTPUT_CSV_FILE, "w") {|f| f.write(output_csv.join("\n"))}
  end
  
  def self.process_for_a_row row, result
    date, user, type, number, point, money, hit_count, hit_money = row
    tally_result = result.tally

    if type == "Lô"
      hit_count = tally_result[number]
      hit_money = 80 * hit_count.to_i * point.to_i
    elsif type == "Đề" && number == result.first
      hit_count = 1
      hit_money = 80 * hit_count * point.to_i
    end

    if hit_count.to_i > 0
      Log.info "\t\t#{date}\t#{user}: trúng #{type}} #{hit_count} nháy #{number}, số điểm: #{point}}, số tiền trùng: #{hit_money}"
    end

    return [date, user, type, number, point, money, hit_count, hit_money].join(",")
  end

  def self.read_input_csv
    rows = CSV.read(INPUT_CSV_FILE)
    rows.group_by{|r| r.first}
  end

  def self.get_result url
    Log.info "\tURL: #{url}"
    result = []
    html = `curl GET #{url}`
    document = Nokogiri::HTML5(html)

    elements = document.search ".kqmb.extendable .v-giai span"

    elements.each_with_index do |element, index|
      next if index == 0
      s_result = element.inner_text

      result << s_result[s_result.length - 2, s_result.length]
    end

    return result
  end
end

InvestmentResult.process