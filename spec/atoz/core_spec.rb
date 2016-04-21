
#
# specifying flor
#
# Tue Mar 22 06:44:32 JST 2016
#

require 'spec_helper'


describe 'Flor a-to-z' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'a procedure on its own' do

    it 'is returned' do

      flon = %{
        sequence
      }

      r = @executor.launch(flon)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq([ '_proc', 'sequence', -1 ])
    end
  end

  describe 'a procedure with a least a child' do

    it 'is executed' do

      flon = %{
        sequence _
      }

      r = @executor.launch(flon)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(nil)
    end
  end

  context 'common _att' do

    describe 'vars' do

      it 'does not set f.ret' do

        flon = %{
          sequence vars: { a: 1 }
        }

        r = @executor.launch(flon)

        expect(r['point']).to eq('terminated')
        expect(r['payload']['ret']).to eq(nil)
      end
    end
  end
end

