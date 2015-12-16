class UsersController < ApplicationController
  require 'twilio-ruby'

  def show

    @user = User.find(params[:id])
    users = User.all

    ImportedContact.where(imported: false).each do |import|

      list = import.list
      puts "________________________________________"
      puts "je suis sur la list #{import.id}"
      users.each do |user|
        "puts _______________________________"
        "je suis entré sur le user #{user.name}"
        list.each do |contact|

          # on met les numéros récupérés au meme format
          phone_numbers = []
          if contact[:phoneNumbers]
            phone_numbers = contact[:phoneNumbers].map do |x|
              n = x[:number].gsub(/[^0-9+]/, '')
              n = n.gsub(/^00/,"+")
              n = n.gsub(/^0/,"+33")
            end
          end
          user_phone_numbers = user.phone_numbers
           puts "numéros de tel récupérés #{phone_numbers}"
           puts "numéros de tel du user #{user_phone_numbers}"
          emails = contact[:emailAddresses] ? contact[:emailAddresses].map{|x| x[:email].downcase.delete(' ')} : []
          puts "emails récupérés #{emails}"
          user_emails = user.emails
          puts "emails du user #{user_emails}"

          # On test si on reconnait le user grace aux numéros de tel ou a une adresse mail
          if phone_numbers.any? {|number| user_phone_numbers.include?(number) } || emails.any? {|email| user_emails.include?(email) }
            puts "---------------------------------------------"
            puts "a reconnu un numéro ou adresse mail chez #{user}"
            # on rajoute des mails si pas dans la BDD
            emails.each do |email|
              if user_emails.include?(email) == false
                puts "------------------------------------------------------------"
                puts "a trouvé un mail (#{email}) qui n'était pas la chez #{user}"
                user_emails << email
                user.save
              end
            end

            # on rajoute des tels si pas dans la BDD
            phone_numbers.each do |number|
              if user_phone_numbers.include?(number) == false
                puts "---------------------------------------------------------------"
                puts "a trouvé un numéro (#{number}) qui n'était pas la chez #{user}"
                user_phone_numbers << number
                user.save
              end
            end

          end

        end

      end

      import.update_attribute :imported, true
      import.save
    end

  end

end
