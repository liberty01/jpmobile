# =SoftBank携帯電話
# J-PHONE, Vodafoneを含む

require 'kconv'

module Jpmobile::Mobile
  # ==Softbank携帯電話
  # Vodafone, Jphoneのスーパクラス。
  class Softbank < AbstractMobile
    # 製造番号を返す。無ければ +nil+ を返す。
    def serial_number
      @request.user_agent =~ /SN(.+?) /
      return $1
    end
    # 位置情報があれば Position のインスタンスを返す。無ければ +nil+ を返す。
    def position
      if params["pos"] =~ /^([NS])(\d+)\.(\d+)\.(\d+\.\d+)([WE])(\d+)\.(\d+)\.(\d+\.\d+)$/
        raise "Unsupported datum" if params["geo"] != "wgs84"
        l = Jpmobile::Position.new
        l.lat = ($1=="N" ? 1 : -1) * Jpmobile::Position.dms2deg($2,$3,$4)
        l.lon = ($5=="E" ? 1 : -1) * Jpmobile::Position.dms2deg($6,$7,$8)
        l.options = params.reject {|x,v| !["pos","geo","x-acr"].include?(x) }
        return l
      else
        return nil
      end
    end
    alias :ident :serial_number
  end
  # ==Vodafone 3G携帯電話(J-PHONE, SoftBank含まず)
  # スーパクラスはSoftbank。
  class Vodafone < Softbank
  end
  # ==SoftBank 2G携帯電話(J-PHONE/Vodafone 2G)
  # スーパクラスはVodafone。
  class Jphone < Vodafone
    # 位置情報があれば Position のインスタンスを返す。無ければ +nil+ を返す。
    def position
      str = @request.env["HTTP_X_JPHONE_GEOCODE"]
      return nil if str.nil? || str == "0000000%1A0000000%1A%88%CA%92%75%8F%EE%95%F1%82%C8%82%B5"
      raise "unsuppoted format" unless str =~ /^(\d\d)(\d\d)(\d\d)%1A(\d\d\d)(\d\d)(\d\d)%1A(.+)$/
      pos = Jpmobile::Position.new
      pos.lat = Jpmobile::Position.dms2deg($1,$2,$3)
      pos.lon = Jpmobile::Position.dms2deg($4,$5,$6)
      pos.options = {"address"=>CGI.unescape($7).toutf8}
      pos.tokyo2wgs84!
      return pos
    end
  end
end