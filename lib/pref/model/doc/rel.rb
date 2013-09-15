module Pref::Model::Doc::Rel
  def self.included(mod)
    mod.has_many :rel_docs, :primary_key => 'id', :foreign_key => 'doc_id', :class_name => 'Pref::DocRel',
      :dependent => :destroy
      
    mod.after_save :save_rel_docs
  end
  
  attr_accessor :_rels
  
  def find_rel_doc_by_name(name)
    return nil unless rel_docs
    rel_docs.each do |rel|
      return rel.rel_doc_id if rel.name == name.to_s
    end
    return nil
  end
  
  def save_rel_docs
    return true  unless _rels
    return false unless id
    return false if @save_rel_docs_callback_flag
    
    @save_rel_docs_callback_flag = true
    
    _rels.each do |k, rel_doc_id|
      name  = k.to_s
      
      if rel_doc_id == ''
        rel_docs.each do |rel|
          rel.destroy if rel.name == name
        end
      else
        rels = []
        rel_docs.each do |rel|
          if rel.name == name
            rels << rel
          end
        end
        
        if rels.size > 1
          rels.each {|rel| rel.destroy}
          rels = []
        end
        
        if rels.size == 0
          rel = Pref::DocRel.new
          rel.doc_id      = id
          rel.content_id  = content_id
          rel.name        = name
          rel.rel_doc_id = rel_doc_id
          rel.save
        else
          rels[0].rel_doc_id = rel_doc_id
          rels[0].save
        end
      end
    end
    
    rel_docs(true)
    return true
  end
end