class Pref::DocRel < ActiveRecord::Base
  include System::Model::Base
  
  belongs_to :rel_doc, :foreign_key => :rel_doc_id, :class_name => 'Pref::Doc'
end
