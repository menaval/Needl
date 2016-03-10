ActiveAdmin.register User do

  permit_params :name, :email, :password, :admin, :picture, :emails, :phone_numbers, :score, :description, :tags, :url

  form do |f|
    f.inputs "Identity" do
      f.input :name
      f.input :email
      f.input :emails
      f.input :phone_numbers
      f.input :score
      f.input :description
      f.input :tags
      f.input :url
      f.file_field :picture
    end
    f.inputs "Admin" do
      f.input :admin
    end
    f.actions
  end

end

