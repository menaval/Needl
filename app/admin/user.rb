ActiveAdmin.register User do

  permit_params :name, :email, :password, :admin, :picture, :emails, :phone_numbers, :score

  form do |f|
    f.inputs "Identity" do
      f.input :name
      f.input :email
      f.input :emails
      f.input :phone_numbers
      f.input :score
      f.file_field :picture
    end
    f.inputs "Admin" do
      f.input :admin
    end
    f.actions
  end

end

