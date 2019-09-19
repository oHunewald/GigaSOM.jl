
import Images, FileIO, ImageMagick, GigaSOM, Colors

# a bit of colors!

function clusterPalette(n; alpha=1.0)
    [Colors.convert(Colors.RGBA,
        Colors.HSVA(
            360.0*(i-1)/n,
            1-0.3*(i%2),
            0.7+0.3*(i%2),
            alpha)) for i in 1:n]
end

function colorRampPalette(c, r)
    k = size(c, 1)
    kr = (k-1)*r
    i = Int64(trunc(kr))

    if i<0
        return c[1,:]
    end

    if i>=(k-1)
        return c[k,:]
    end

    a = kr-i
    return (1-a)*c[i+1,:] + a*c[i+2,:]
end

function expressionPalette(n; alpha=1.0)
    #data taken from a modified RbYlBu from EmbedSOM, which was originally taken from ColorBrewer
    ryb=Array{Float64,2}(
        [33    38  149;
         53   101  180;
        100   157  209;
        145   195  226;
        184   217  200;
        255   255  168;
        254   224  144;
        253   174   97;
        244   109   67;
        215    48   39;
        165     0   38])

    [Colors.RGBA(x[1], x[2], x[3], alpha) for x in [colorRampPalette(ryb, (i-1)/(n-1)) for i in 1:n]/255.0]
end

function rasterize(res::Tuple{Int64, Int64}, points::Array{Float64, 2}, colors::Array{Float64, 2};
    xlim = (minimum(points[:,1]), maximum(points[:,1])), ylim = (minimum(points[:,2]), maximum(points[:,2]))
    )::Array{Float64, 3}

    # processing start
    # (note: `precision^2` should be smaller than integer size!)
    precision=100000

    ra = zeros(Int64, 4, res[1], res[2])
    mins = [xlim[1], ylim[1]]
    iszs = [res[1]/(xlim[2]-xlim[1]), res[2]/(ylim[2]-ylim[1])]
    pos = zeros(Int64, 2)
    src = zeros(Int64, 4)
    dst = zeros(Int64, 4)
    for i in 1:size(points,2)
        @inbounds begin
            pos = trunc.(Int64, (points[:,i]-mins).*iszs) .+ 1
            if pos[1]<1 || pos[1] > res[1] || pos[2]<1 || pos[2]>res[2]
                continue
            end
            src = trunc.(Int64, precision*colors[:,i])

            #premultiply alpha
            src[1:3] *= src[4]
            src[1:3] .÷= precision

            #blend
            dst=ra[:,pos[1],pos[2]]
            ra[:,pos[1],pos[2]]=src+dst-((src[4]*dst).÷precision)
        end
    end

    #unmultiply alpha and convert back to floats
    raf = zeros(Float64, 4, res[1], res[2])
    for i in 1:res[1]
        for j in 1:res[2]
            @inbounds raa=ra[4,i,j]
            if raa == 0
                continue
            end
            @inbounds begin
                raf[1,i,j]=ra[1,i,j]/raa
                raf[2,i,j]=ra[2,i,j]/raa
                raf[3,i,j]=ra[3,i,j]/raa
                raf[4,i,j]=ra[4,i,j]/precision
            end
        end
    end

    raf
end

function expand_points(radius, raf::Array{Float64, 3})::Array{Float64, 3}
    rt=radius*radius
    r=Int64(ceil(radius))
    res=zeros(Float64, size(raf))
    for x in 1:size(raf, 2)
        for y in 1:size(raf, 3)
            sr=0.0
            sg=0.0
            sb=0.0
            pia=1.0
            w=0.0
            for ox in (-r):r
                for oy in (-r):r
                    if ox*ox+oy*oy > rt
                        continue
                    end
                    tx=x+ox
                    ty=y+oy
                    if tx < 1 || tx > size(raf,2) || ty < 1 || ty > size(raf, 3)
                        continue
                    end
                    @inbounds begin
                        sr+=raf[1,tx,ty]*raf[4,tx,ty]
                        sg+=raf[2,tx,ty]*raf[4,tx,ty]
                        sb+=raf[3,tx,ty]*raf[4,tx,ty]
                        w+=raf[4,tx,ty]
                        pia*=1-raf[4,tx,ty]
                    end
                end
            end
            if w>0
                @inbounds begin
                    res[1,x,y]=sr/w
                    res[2,x,y]=sg/w
                    res[3,x,y]=sb/w
                    res[4,x,y]=1-pia
                end
            end
        end
    end
    res
end
