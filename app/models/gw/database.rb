class Gw::Database < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :gw
end
