
#
# specifying flor
#
# Sat Apr  2 11:18:12 JST 2016
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'cond' do

    it 'has no effect it it has no children' do

      rad = %{
        push f.l 0
        cond
        push f.l 1
      }

      r = @executor.launch(rad, payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(1)
      expect(r['payload']['l']).to eq([ 0, 1 ])
    end

    it 'triggers' do

      rad = %{
        set a 4
        cond
          a < 4
          "less than four"
          a < 7
          "less than seven"
          a < 10
          "less than ten"
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('less than seven')
    end

    it 'has no effect when there is no match' do

      rad = %{
        7
        set a 10
        cond
          a < 4 ;; "less than four"
          a < 7 ;; "less than seven"
          a < 10 ;; "less than ten"
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(7)
    end

    it 'defaults to the "else" if present' do

      rad = %{
        set a 11
        cond
          a < 4 ;; "less than four"
          a < 7 ;; "less than seven"
          else ;; "ten or bigger"
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('ten or bigger')
    end

    it 'does not mind an else followed by nothing' do

      rad = %{
        7
        set a 11
        cond
          a < 4 ;; "less than four"
          a < 7 ;; "less than seven"
          else
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(7)
    end

    it 'is OK with a true instead of an "else"' do

      rad = %{
        set a 12
        cond
          a < 4 ;; "less than four"
          a < 7 ;; "less than seven"
          true ;; "ten or bigger"
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('ten or bigger')
    end

    it 'does not mind a true followed by nothing' do

      rad = %{
        7
        set a 12
        cond
          a < 4 ;; "less than four"
          a < 7 ;; "less than seven"
          true
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(7)
    end
  end
end

