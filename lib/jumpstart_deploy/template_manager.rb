# frozen_string_literal: true

require "yaml"

module JumpstartDeploy
  class TemplateManager
    TEMPLATES_PATH = File.expand_path("templates", __dir__)

    def self.load_template(name)
      template_file = File.join(TEMPLATES_PATH, "#{name}.yml")
      raise "Template '#{name}' not found" unless File.exist?(template_file)

      YAML.load_file(template_file)
    end

    def self.available_templates
      Dir[File.join(TEMPLATES_PATH, "*.yml")].map do |file|
        File.basename(file, ".yml")
      end
    end

    def self.apply_template(config, name)
      template = load_template(name)

      # Deep merge template configurations
      config.merge(template) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          old_val.merge(new_val)
        else
          new_val
        end
      end
    end
  end
end
