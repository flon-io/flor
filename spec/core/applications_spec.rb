
#
# specifying flor
#
# Sat Feb 20 20:57:16 JST 2016
#

require 'spec_helper'


describe 'Flor core' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'a value on its own' do

    it 'returns itself' do

      r = @executor.launch(
        %q{
          3
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq(3)
    end

    it 'returns itself' do

      r = @executor.launch(
        %q{
          3 tags: 'xyz'
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq(3)

      expect(
        @executor.journal
          .collect { |m|
            [ m['point'], m['nid'], (m['tags'] || []).join(',') ].join(':')
          }
          .join("\n")
      ).to eq(%w[
        execute:0:
        execute:0_1:
        receive:0:
        execute:0_2:
        execute:0_2_0:
        execute:0_2_0_0:
        receive:0_2_0:
        execute:0_2_0_1:
        receive:0_2_0:
        entered:0_2:xyz
        receive:0_2:
        receive:0:
        left:0_2:xyz
        receive::
        terminated::
      ].join("\n"))
    end
  end

  describe 'a procedure reference' do

    it 'returns the referenced procedure' do

      r = @executor.launch(
        %q{
          sequence
        })

      expect(r).to have_terminated_as_point

      expect(
        r['payload']['ret']
      ).to eq(
        [ '_proc', { 'proc' => 'sequence' }, -1 ]
      )
    end
  end

  describe 'a function reference' do

    it 'returns the referenced function' do

      r = @executor.launch(
        %q{
          sequence
            define sum a, b
              # empty
            sum
        })

      expect(r).to have_terminated_as_point

      expect(r['payload']['ret'][0]).to eq('_func')
      expect(r['payload']['ret'][1]['nid']).to eq('0_0')
      expect(r['payload']['ret'][1]['cnid']).to eq('0')
      expect(r['payload']['ret'][1]['fun']).to eq(0)
      expect(r['payload']['ret'][1]['tree'][0]).to eq('define')
    end
  end

  describe 'a function call' do

    it 'works' do

      r = @executor.launch(
        %q{
          sequence
            define sum a, b
              +
                a
                b
            sum 1 2
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq(3)
    end

    it 'runs each time with a different subnid' do

      r = @executor.launch(
        %q{
          sequence
            define sub i
              push f.l
                #val $(node.nid)
                [ i, node.nid ]
              + i 1
            sub 0
            sub 1
            sub 2
        },
        payload: { 'l' => [] })

      expect(r).to have_terminated_as_point

      expect(
        r['payload']['ret']
      ).to eq(
        3
      )
      expect(
        r['payload']['l']
      ).to eq(
        [ [ 0, '0_0_2_1_1-1' ], [ 1, '0_0_2_1_1-2' ], [ 2, '0_0_2_1_1-3' ] ]
      )
    end

    it 'works with an anonymous function' do

      r = @executor.launch(
        %q{
          sequence
            set sum
              def x y
                +
                  x
                  y
            sum 7 3
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq(10)
    end

    it 'works with an anonymous function (f.ret)' do

      r = @executor.launch(
        %q{
          def x y \ (+ x y)
          f.ret 6 2
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq(8)
    end

    it 'works with an anonymous function (paren)' do

      r = @executor.launch(
        %q{
          (def x y \ (+ x y)) 7 2
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq(9)
    end

    it 'works with default values for parameters' do

      r = @executor.launch(
        %q{
          (def x y:(+ 1 1) \ (+ x y)) 7
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq(9)
    end

    it 'works with named parameters out of orders' do

      r = @executor.launch(
        %q{
          define f a b
            + a (/ b 2)
          [ (f 1 2) (f b: 4 a: 1) ]
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq([ 2, 3 ])
    end

    it 'works with a mix of default values and named parameters' do

      r = @executor.launch(
        %q{
          define f a b:2 c:(3 + b)
            + a (2 * b) (3 * c)
          [ (f 2 1)
            (f b: 4 a: 1)
            (f a: 2 c: 1 b: -2) ]
        })

      expect(r).to have_terminated_as_point
      expect(r['payload']['ret']).to eq([ 16, 30, 1 ])
    end

    it "has access to the 'arguments' var" do

      r = @executor.launch(
        %q{
          define f
            arguments
          f 1 [ 2 3 ] d: 'four'
        })

      expect(r).to have_terminated_as_point

      expect(
        r['payload']['ret']
      ).to eq([
        [ nil, 1 ], [ nil, [ 2, 3 ] ], [ 'd', 'four' ]
      ])
    end

    it "has access to the args/argv/arga var" do

      r = @executor.launch(
        %q{
          define f
            [ args, args.0, arga.1, argv.2 ]
          f 1 [ 2 3 ] d: 'four'
        })

      expect(r).to have_terminated_as_point

      expect(
        r['payload']['ret']
      ).to eq([
        [ 1, [ 2, 3 ], 'four' ],
        1, [ 2, 3 ], 'four'
      ])
    end

    it "has access to the argh/argd var" do

      r = @executor.launch(
        %q{
          define f
            [ argh, argh.d, argd.d ]
          f 1 [ 2 3 ] d: 'four'
        })

      expect(r).to have_terminated_as_point

      expect(
        r['payload']['ret']
      ).to eq([
        { 'd' => 'four' },
        'four',
        'four'
      ])
    end

    context 'with a block' do

# TODO closure?

      it 'wraps the block in a function' do

        r = @executor.launch(
          %q{
            define f count
              each (range 0 count)
                yield _
            set l []
            f 3
              push l 'a'
              push l 'b'
          })

        expect(r).to have_terminated_as_point
        expect(r['vars']['l']).to eq(%w[ a b ] * 3)
      end

      it "takes the function if it's the only child in the block" do

        r = @executor.launch(
          %q{
            define f count
              each (range 0 count)
                yield idx
            set l []
            f 3
              def i
                push l (2 * i)
          })

        expect(r).to have_terminated_as_point
        expect(r['vars']['l']).to eq([ 0, 2, 4 ])
      end

      it 'yields' do

        r = @executor.launch(
          %q{
            #define f i
            #  * i (yield _)
            #f 5
            #  10

            define f i
              + i (yield i)
            f 5
              def j
                * 3 j
          })

        expect(r).to have_terminated_as_point
        expect(r['payload']['ret']).to eq(20)
      end

      it 'is ok with an underscore and a block as args' do

        r = @executor.launch(
          %q{
            define f
              * 2 (yield _)
            f _
              7
          })

        expect(r).to have_terminated_as_point
        expect(r['payload']['ret']).to eq(14)
      end

      it 'is ok with the block as single argument' do

        r = @executor.launch(
          %q{
            define f
              * 2 (yield _)
            f
              14
          })

        expect(r).to have_terminated_as_point
        expect(r['payload']['ret']).to eq(28)
      end
    end
  end

  describe 'a closure' do

    it 'works (read)' do

      r = @executor.launch(
        %q{
          sequence
            define make_adder x
              def y
                +
                  x
                  y
            set add3
              make_adder 3
            add3 7
        })

      expect(r).to have_terminated_as_point

      expect(r['vars'].keys.sort).to eq(%w[ add3 make_adder ])

      expect(r['vars']['make_adder'][0]).to eq('_func')
      expect(r['vars']['make_adder'][1]['nid']).to eq('0_0')
      expect(r['vars']['make_adder'][1]['cnid']).to eq('0')
      expect(r['vars']['make_adder'][1]['fun']).to eq(0)
      expect(r['vars']['make_adder'][1]['tree'][0]).to eq('define')

      expect(r['vars']['add3'][0]).to eq('_func')
      expect(r['vars']['add3'][1]['nid']).to eq('0_0_2-1')
      expect(r['vars']['add3'][1]['cnid']).to eq('0_0-1')
      expect(r['vars']['add3'][1]['fun']).to eq(1)
      expect(r['vars']['add3'][1]['tree'][0]).to eq('def')

      expect(r['payload']['ret']).to eq(10)

      nodes = @executor.execution['nodes']

      expect(nodes.keys).to eq(%w[ 0 0_0-1 ])
    end

    it 'works (write)' do

      # SICP p. 222

      r = @executor.launch(
        %q{
          sequence
            define make-withdraw bal
              def amt
                setr bal \ - bal amt
            set w0
              make-withdraw 100
            push f.l
              w0 77
            push f.l
              w0 13
        },
        payload: { 'l' => [] })

      expect(r).to have_terminated_as_point
      expect(r['payload']['l']).to eq([ 23, 10 ])
    end

    it 'works (write) (2 instances)' do

      r = @executor.launch(
        %q{
          sequence
            define make-withdraw bal
              def amt
                setr bal (- bal amt)
            set w0 (make-withdraw 100)
            set w1 (make-withdraw 100)
            push f.l (w0 77)
            push f.l (w0 13)
            push f.l (w1 17)
            push f.l (w1 3)
            push f.l (w0 12)
        },
        payload: { 'l' => [] })

      expect(r).to have_terminated_as_point
      expect(r['payload']['l']).to eq([ 23, 10, 83, 80, -2 ])
#puts "-" * 80
#pp r
#puts "-" * 80
#pp @executor.execution['nodes']
    end
  end

  describe 'args/argv/argh/argd' do

    it 'cannot be found outside of a fun call (args)' do

      r = @executor.launch('args')

      expect(r['point']).to eq('failed')
      expect(r['error']['lin']).to eq(1)
      expect(r['error']['msg']).to eq('cannot find "args"')
    end

    it 'cannot be found outside of a fun call (argv)' do

      r = @executor.launch('argv')

      expect(r['point']).to eq('failed')
      expect(r['error']['lin']).to eq(1)
      expect(r['error']['msg']).to eq('cannot find "argv"')
    end

    it 'cannot be found outside of a fun call (argh)' do

      r = @executor.launch('argh')

      expect(r['point']).to eq('failed')
      expect(r['error']['lin']).to eq(1)
      expect(r['error']['msg']).to eq('cannot find "argh"')
    end

    it 'cannot be found outside of a fun call (argd)' do

      r = @executor.launch('argd')

      expect(r['point']).to eq('failed')
      expect(r['error']['lin']).to eq(1)
      expect(r['error']['msg']).to eq('cannot find "argd"')
    end
  end
end

