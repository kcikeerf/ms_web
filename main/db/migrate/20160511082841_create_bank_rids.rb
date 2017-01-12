class CreateBankRids < ActiveRecord::Migration
  def change
    create_table :bank_rids do |t|
      t.string :rid
      t.timestamps
    end

    [*0..999].each{|num|
       br = BankRid.new(:rid=> num.to_s.rjust(3, '0'))
       br.save!
    }
  end
end
