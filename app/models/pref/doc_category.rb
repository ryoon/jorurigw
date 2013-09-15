class Pref::DocCategory < ActiveRecord::Base
  include System::Model::Base
  
  belongs_to :category, :foreign_key => :category_id, :class_name => 'Pref::Category'
end
