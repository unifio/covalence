require 'yaml'

class HieraSyntaxService
  def self.check_yaml(filelist)
    errors = []

    [*filelist].each do |hiera_file|
      begin
        YAML.load_file(hiera_file)
      rescue StandardError => error
        errors << "ERROR: Failed to parse #{hiera_file}: #{error}"
      end
    end

    errors.map { |e| e.to_s }
  end
end
