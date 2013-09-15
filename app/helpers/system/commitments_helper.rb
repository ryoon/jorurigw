module System::CommitmentsHelper
  def commitments_view(item)
    return '' unless item.class.include?(System::Model::Unid::Commitment)
    return render(:partial => 'system/admin/commitments/view', :locals => {:item => item})
  end
end