module EasyFormat
  module DateTime
    module_function

    def yyyymmdd(date = Time.now)
      date = ::Time.parse(date) unless date.is_a?(Time)
      date.strftime('%Y%m%d')
    end

    def hhmmss(time = Time.now)
      time = ::Time.parse(time) unless time.is_a?(Time)
      time.strftime('%H%M%S')
    end

    def yyyymmdd_hhmmss(date_and_time = Time.now)
      date_and_time = ::Time.parse(date_and_time) unless date_and_time.is_a?(Time)
      date_and_time.strftime('%Y%m%d_%H%M%S')
    end
  end
end
