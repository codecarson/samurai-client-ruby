require 'spec_helper'

describe "PaymentMethod" do
  before do
    @params = {
      :first_name   => "FirstName",
      :last_name    => "LastName",
      :address_1    => "123 Main St.",
      :address_2    => "Apt #3",
      :city         => "Chicago",
      :state        => "IL",
      :zip          => "10101",
      :card_number  => "4111-1111-1111-1111",
      :cvv          => "123",
      :expiry_month => '03',
      :expiry_year  => "2015",
    }
  end

  describe 'S2S #create' do
    it 'should be successful' do
      pm = Samurai::PaymentMethod.create @params
      Samurai::PaymentMethod.find(pm.token).tap do |pm|
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_true
        pm.first_name.should  == @params[:first_name]
        pm.last_name.should   == @params[:last_name]
        pm.address_1.should   == @params[:address_1]
        pm.address_2.should   == @params[:address_2]
        pm.city.should        == @params[:city]
        pm.state.should       == @params[:state]
        pm.zip.should         == @params[:zip]
        pm.last_four_digits.should == @params[:card_number][-4, 4]
        pm.expiry_month.should  == @params[:expiry_month].to_i
        pm.expiry_year.should   == @params[:expiry_year].to_i
      end
    end
    describe 'fail on input.card_number' do
      it 'should return is_blank' do
        pm = Samurai::PaymentMethod.create @params.merge(:card_number => '')
        pm.is_sensitive_data_valid.should be_false
        pm.should have_the_error('input.card_number', 'The card number was blank.')
      end
      it 'should return too_short' do
        pm = Samurai::PaymentMethod.create @params.merge(:card_number => '4111-1')
        pm.is_sensitive_data_valid.should be_false
        pm.should have_the_error('input.card_number', 'The card number was too short.')
      end
      it 'should return too_long' do
        pm = Samurai::PaymentMethod.create @params.merge(:card_number => '4111-1111-1111-1111-11')
        pm.is_sensitive_data_valid.should be_false
        pm.should have_the_error('input.card_number', 'The card number was too long.')
      end
      it 'should return failed_checksum' do
        pm = Samurai::PaymentMethod.create @params.merge(:card_number => '4111-1111-1111-1234')
        pm.is_sensitive_data_valid.should be_false
        pm.should have_the_error('input.card_number', 'The card number was invalid.')
      end
    end
    describe 'fail on input.cvv' do
      it 'should return too_short' do
        pm = Samurai::PaymentMethod.create @params.merge(:cvv => '1')
        pm.is_sensitive_data_valid.should be_false
        pm.should have_the_error('input.cvv', 'The CVV was too short.')
      end
      it 'should return too_long' do
        pm = Samurai::PaymentMethod.create @params.merge(:cvv => '111111')
        pm.is_sensitive_data_valid.should be_false
        pm.should have_the_error('input.cvv', 'The CVV was too long.')
      end
      it 'should return not_numeric' do
        pm = Samurai::PaymentMethod.create @params.merge(:cvv => 'abcd1')
        pm.is_sensitive_data_valid.should be_false
        pm.should have_the_error('input.cvv', 'The CVV was invalid.')
      end
    end
    describe 'fail on input.expiry_month' do
      it 'should return is_blank' do
        pm = Samurai::PaymentMethod.create @params.merge(:expiry_month => '')
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_false
        pm.should have_the_error('input.expiry_month', 'The expiration month was blank.')
      end
      it 'should return is_invalid' do
        pm = Samurai::PaymentMethod.create @params.merge(:expiry_month => 'abcd')
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_false
        pm.should have_the_error('input.expiry_month', 'The expiration month was invalid.')
      end
    end
    describe 'fail on input.expiry_year' do
      it 'should return is_blank' do
        pm = Samurai::PaymentMethod.create @params.merge(:expiry_year => '')
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_false
        pm.should have_the_error('input.expiry_year', 'The expiration year was blank.')
      end
      it 'should return is_invalid' do
        pm = Samurai::PaymentMethod.create @params.merge(:expiry_year => 'abcd')
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_false
        pm.should have_the_error('input.expiry_year', 'The expiration year was invalid.')
      end
    end
  end

  describe 'S2S #update' do
    before do
      @params = {
        :first_name   => "FirstNameX",
        :last_name    => "LastNameX",
        :address_1    => "123 Main St.X",
        :address_2    => "Apt #3X",
        :city         => "ChicagoX",
        :state        => "IL",
        :country      => "US",
        :zip          => "10101",
        :card_number  => "5454-5454-5454-5454",
        :cvv          => "456",
        :expiry_month => '05',
        :expiry_year  => "2016",
      }
      @pm = Samurai::PaymentMethod.find create_payment_method(default_payment_method_params)[:payment_method_token]
    end
    it 'should be successful' do
      @pm.update_attributes @params
      Samurai::PaymentMethod.find(@pm.token).tap do |pm|
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_true
        pm.first_name.should  == @params[:first_name]
        pm.last_name.should   == @params[:last_name]
        pm.address_1.should   == @params[:address_1]
        pm.address_2.should   == @params[:address_2]
        pm.city.should        == @params[:city]
        pm.state.should       == @params[:state]
        pm.zip.should         == @params[:zip]
        pm.country.should     == @params[:country]
        pm.last_four_digits.should == @params[:card_number][-4, 4]
        pm.expiry_month.should  == @params[:expiry_month].to_i
        pm.expiry_year.should   == @params[:expiry_year].to_i
      end
    end
    it 'should be successful preserving sensitive data' do
      _params = @params.merge({
        :card_number => '****-****-****-5454',
        :cvv => '***',
      })
      @pm.update_attributes _params
      Samurai::PaymentMethod.find(@pm.token).tap do |pm|
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_true
        pm.first_name.should  == @params[:first_name]
        pm.last_name.should   == @params[:last_name]
        pm.address_1.should   == @params[:address_1]
        pm.address_2.should   == @params[:address_2]
        pm.city.should        == @params[:city]
        pm.state.should       == @params[:state]
        pm.zip.should         == @params[:zip]
        pm.country.should     == @params[:country]
        pm.last_four_digits.should == '1111'
        pm.expiry_month.should  == @params[:expiry_month].to_i
        pm.expiry_year.should   == @params[:expiry_year].to_i
      end
    end
    describe 'fail on input.card_number' do
      it 'should return too_short' do
        @pm.update_attributes @params.merge(:card_number => '4111-1')
        @pm.is_sensitive_data_valid.should be_false
        @pm.should have_the_error('input.card_number', 'The card number was too short.')
      end
      it 'should return too_long' do
        @pm.update_attributes @params.merge(:card_number => '4111-1111-1111-1111-11')
        @pm.is_sensitive_data_valid.should be_false
        @pm.should have_the_error('input.card_number', 'The card number was too long.')
      end
      it 'should return failed_checksum' do
        @pm.update_attributes @params.merge(:card_number => '4111-1111-1111-1234')
        @pm.is_sensitive_data_valid.should be_false
        @pm.should have_the_error('input.card_number', 'The card number was invalid.')
      end
    end
    describe 'fail on input.cvv' do
      it 'should return too_short' do
        @pm.update_attributes @params.merge(:cvv => '1')
        @pm.is_sensitive_data_valid.should be_false
        @pm.should have_the_error('input.cvv', 'The CVV was too short.')
      end
      it 'should return too_long' do
        @pm.update_attributes @params.merge(:cvv => '111111')
        @pm.is_sensitive_data_valid.should be_false
        @pm.should have_the_error('input.cvv', 'The CVV was too long.')
      end
    end
    describe 'fail on input.expiry_month' do
      it 'should return is_blank' do
        @pm.update_attributes @params.merge(:expiry_month => '')
        @pm.is_sensitive_data_valid.should be_true
        @pm.is_expiration_valid.should be_false
        @pm.should have_the_error('input.expiry_month', 'The expiration month was blank.')
      end
      it 'should return is_invalid' do
        @pm.update_attributes @params.merge(:expiry_month => 'abcd')
        @pm.is_sensitive_data_valid.should be_true
        @pm.is_expiration_valid.should be_false
        @pm.should have_the_error('input.expiry_month', 'The expiration month was invalid.')
      end
    end
    describe 'fail on input.expiry_year' do
      it 'should return is_blank' do
        @pm.update_attributes @params.merge(:expiry_year => '')
        @pm.is_sensitive_data_valid.should be_true
        @pm.is_expiration_valid.should be_false
        @pm.should have_the_error('input.expiry_year', 'The expiration year was blank.')
      end
      it 'should return is_invalid' do
        @pm.update_attributes @params.merge(:expiry_year => 'abcd')
        @pm.is_sensitive_data_valid.should be_true
        @pm.is_expiration_valid.should be_false
        @pm.should have_the_error('input.expiry_year', 'The expiration year was invalid.')
      end
    end
  end

  describe '#find' do
    before do
      @token = Samurai::PaymentMethod.create(@params).token
    end
    it 'should be successful' do
      Samurai::PaymentMethod.find(@token).tap do |pm|
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_true
        pm.first_name.should  == @params[:first_name]
        pm.last_name.should   == @params[:last_name]
        pm.address_1.should   == @params[:address_1]
        pm.address_2.should   == @params[:address_2]
        pm.city.should        == @params[:city]
        pm.state.should       == @params[:state]
        pm.zip.should         == @params[:zip]
        pm.country.should     == @params[:country]
        pm.last_four_digits.should == @params[:card_number][-4, 4]
        pm.expiry_month.should  == @params[:expiry_month].to_i
        pm.expiry_year.should   == @params[:expiry_year].to_i
      end
    end
    it 'should fail on an invalid token' do
      lambda do
        Samurai::PaymentMethod.find('abc123')
      end.should raise_error(ActiveResource::ResourceNotFound)
    end
  end

  describe '#redact' do
    before do
      @pm = Samurai::PaymentMethod.create(@params)
    end
    it 'should be successful' do
      @pm.is_redacted.should be_false
      @pm.redact
      @pm.tap do |pm|
        pm.is_redacted.should be_true
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_true
        pm.first_name.should  == @params[:first_name]
        pm.last_name.should   == @params[:last_name]
        pm.address_1.should   == @params[:address_1]
        pm.address_2.should   == @params[:address_2]
        pm.city.should        == @params[:city]
        pm.state.should       == @params[:state]
        pm.zip.should         == @params[:zip]
        pm.country.should     == @params[:country]
        pm.last_four_digits.should == @params[:card_number][-4, 4]
        pm.expiry_month.should  == @params[:expiry_month].to_i
        pm.expiry_year.should   == @params[:expiry_year].to_i
      end
    end
    #it 'should not allow an authorize' do
    #  lambda do
    #    @pm.redact
    #    @authorize = Samurai::Processor.authorize(@pm.token, 100.0)
    #  end.should raise_error(ActiveResource::ResourceNotFound)
    #end
  end

  describe '#retain' do
    before do
      @pm = Samurai::PaymentMethod.create(@params)
    end
    it 'should be successful' do
      @pm.is_retained.should be_false
      @pm.retain
      @pm.tap do |pm|
        pm.is_retained.should be_true
        pm.is_sensitive_data_valid.should be_true
        pm.is_expiration_valid.should be_true
        pm.first_name.should  == @params[:first_name]
        pm.last_name.should   == @params[:last_name]
        pm.address_1.should   == @params[:address_1]
        pm.address_2.should   == @params[:address_2]
        pm.city.should        == @params[:city]
        pm.state.should       == @params[:state]
        pm.zip.should         == @params[:zip]
        pm.country.should     == @params[:country]
        pm.last_four_digits.should == @params[:card_number][-4, 4]
        pm.expiry_month.should  == @params[:expiry_month].to_i
        pm.expiry_year.should   == @params[:expiry_year].to_i
      end
    end
  end

end
