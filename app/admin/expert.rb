ActiveAdmin.register Expert do

  permit_params :name, :picture

  form do |f|
    f.inputs "Identity" do
      f.input :name
      f.file_field :picture
    end
    f.actions
  end

end