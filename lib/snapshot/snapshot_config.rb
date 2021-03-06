module Snapshot
  class SnapshotConfig
    
    # @return (SnapshotFile)
    attr_accessor :snapshot_file

    # @return (Array) List of simulators to use
    attr_accessor :devices

    # @return (Array) A list of languages which should be used
    attr_accessor :languages
    
    # @return (String) The iOS version (e.g. 8.1)
    attr_accessor :ios_version

    # @return (String) The path to the project/workspace
    attr_accessor :project_path

    # @return (String) The name of a scheme, manually set by the user using the config file
    attr_accessor :manual_scheme

    # @return (String) The path to the JavaScript file to use
    attr_accessor :manual_js_file

    # @return (String) The path, in which the screenshots should be stored
    attr_accessor :screenshots_path


    # A shared singleton
    def self.shared_instance
      @@instance ||= SnapshotConfig.new
    end

    # @param path (String) the path to the config file to use (including the file name)
    def initialize(path = './Snapfile')
      set_defaults

      if path and File.exists?path
        self.snapshot_file = SnapshotFile.new(path, self)
      else
        Helper.log.error "Could not find './Snapfile'. It is recommended to create a file into the current directory. Using the defaults now."
      end
    end

    def set_defaults
      self.ios_version = '8.1'

      self.devices = [
        "iPhone 6 (#{self.ios_version} Simulator)",
        "iPhone 6 Plus (#{self.ios_version} Simulator)",
        "iPhone 5 (#{self.ios_version} Simulator)",
        "iPhone 4s (#{self.ios_version} Simulator)"
      ]

      self.languages = [
        'de-DE',
        'en-US'
      ]

      self.screenshots_path = './screenshots'

      self.project_path = (Dir.glob("./*.xcworkspace").first rescue nil)
      self.project_path ||= (Dir.glob("./*.xcodeproj").first rescue nil)
    end

    # Getters

    # Returns the file name of the project
    def project_name
      (self.project_path.split('/').last.split('.').first rescue nil)
    end

    # The JavaScript UIAutomation file
    def js_file
      files = Dir.glob("./*.js").delete_if { |path| path.include?"SnapshotHelper.js" }
      if files.count == 1
        return files.first
      else
        raise "Could not determine which UIAutomation file to use. Please pass a path to your Javascript file using 'js_path'.".red
      end
    end

    # The scheme to use (either it's set, or there is only one, or user has to enter it)
    def scheme
      begin
        command = "cd '#{project_path.split('/')[0..-2].join('/')}'; xcodebuild -list"
        schemes = `#{command}`.split("Schemes:").last.split("\n").each { |a| a.strip! }.delete_if { |a| a == '' }
        Helper.log.debug "Found available schemes: #{schemes}"

        self.manual_scheme = schemes.first if schemes.count == 1

        if self.manual_scheme
          if not schemes.include?manual_scheme
            raise "Could not find requested scheme '#{self.manual_scheme}' in Xcode's schemes #{schemes}"
          else
            return self.manual_scheme
          end
        else
          # We have to ask the user first
          puts "Found the following schemes in your project:".green
          puts "You can use 'scheme \"Name\"' in your Snapfile".green
          puts "--------------------------------------------".green
          while not schemes.include?self.manual_scheme
            schemes.each_with_index do |current, index|
              puts "#{index + 1}) #{current}"
            end
            val = gets.strip.to_i
            if val > 0
              self.manual_scheme = (schemes[val - 1] rescue nil)
            end
          end
          return self.manual_scheme
        end
      rescue Exception => ex
        raise "Could not fetch available schemes: #{ex}".red
      end
    end
  end
end