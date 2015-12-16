ActiveAdmin.register User do

  permit_params :name, :email, :password, :admin, :picture, :emails

  form do |f|
    f.inputs "Identity" do
      f.input :name
      f.input :email
      f.input :emails
      f.file_field :picture
    end
    f.inputs "Admin" do
      f.input :admin
    end
    f.actions
  end

end

