require 'spec_helper'

describe "Orders", type: :feature, js: true do
  stub_authorization!

  let(:order) { create(:order_with_line_items) }
  let(:line_item) { order.line_items.first }
  let(:bundle) { line_item.product }
  let(:parts) { (1..3).map { create(:variant) } }

  before do
    bundle.parts << [parts]
    line_item.update_attributes!(quantity: 3)
    order.reload.create_proposed_shipments
    order.finalize!
  end

  it "allows admin to edit product bundle" do
    visit spree.edit_admin_order_path(order)

    within("table.product-bundles") do
      find(".edit-line-item").click
      fill_in "quantity", :with => "2"
      find(".save-line-item").click

      sleep(1) # avoid odd "cannot rollback - no transaction is active: rollback transaction"
    end
  end

  if Spree.solidus_gem_version < Gem::Version.new('2.5')
    context 'Adding tracking number' do
      let(:tracking_number) { 'AA123' }

      before { visit spree.edit_admin_order_path(order) }

      it 'allows admin to edit tracking' do
        expect(page).not_to have_content tracking_number
        within '.show-tracking' do
          find('.fa-edit').click
        end
        within '.edit-tracking' do
          expect(page).to have_selector 'input[name="tracking"]'
          fill_in :tracking, with: tracking_number
          find('.fa-ok').click
          expect(page).not_to have_selector 'input[name="tracking"]'
        end
        expect(page).to have_content tracking_number
      end
    end

    context 'Changing carrier/shipping costs' do
      before do
        visit spree.edit_admin_order_path(order)
      end

      it 'allows admin to edit shipping costs' do
        expect(page).not_to have_content 'UPS Ground $100.00'
        within '.show-method' do
          find('.fa-edit').click
        end
        within '.edit-method' do
          find('.fa-ok').click
        end
        expect(page).to have_content 'UPS Ground $100.00'
      end
    end
  else
    context 'Adding tracking number' do
      let(:tracking_number) { 'AA123' }

      before { visit spree.edit_admin_order_path(order) }

      it 'allows admin to edit tracking' do
        within '.edit-tracking' do
          expect(page).not_to have_content tracking_number
          find('.js-edit').click
          expect(page).to have_selector 'input[name="tracking"]'
          fill_in :tracking, with: tracking_number
          find('.js-save').click
          expect(page).not_to have_selector 'input[name="tracking"]'
          expect(page).to have_content tracking_number
        end
      end
    end

    context 'Changing carrier/shipping costs' do
      let(:carrier_name) { 'Fedex' }
      let(:select_name) { 'selected_shipping_method_id' }

      before do
        create :shipping_method, name: carrier_name
        visit spree.edit_admin_order_path(order)
      end

      it 'allows admin to edit shipping costs' do
        within '.edit-shipping-method' do
          expect(page).not_to have_content carrier_name
          find('.js-edit').click
          expect(page).to have_selector "select[name='#{select_name}']"
          select "#{carrier_name} $10.00", from: select_name
          find('.js-save').click
          expect(page).not_to have_selector "select[name='#{select_name}']"
          expect(page).to have_content carrier_name
        end
      end
    end
  end
end
