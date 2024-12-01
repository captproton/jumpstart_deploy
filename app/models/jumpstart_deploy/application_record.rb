# frozen_string_literal: true

module JumpstartDeploy
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
