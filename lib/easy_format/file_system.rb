module EasyFormat
  module File
    module_function

    def windows_friendly_name(name, type: :file) # type options: :file or :path
      type == :file ? name.gsub(%r{[\x00/\\:\*\?\"<>\|]}, '_') : name.gsub(/[\x00\*\?\"<>\|]/, '_')
    end
  end

  module Directory
    module_function

    def ensure_trailing_slash(directory)
      return nil if directory.nil?
      ::File.join(directory, '')
    end
  end
end
