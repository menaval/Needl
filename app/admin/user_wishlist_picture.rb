ActiveAdmin.register UserWishlistPicture do

permit_params :picture, :user_id

  form do |f|
    f.inputs "Picture" do
      f.input :user
      f.file_field :picture
    end
    f.actions
  end

end