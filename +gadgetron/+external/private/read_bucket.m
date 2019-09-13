function bucket = read_bucket(socket)

    meta = read_bucket_meta(socket);
    bucket.data      = read_bundle(socket, meta.data, meta.data_stats);
    bucket.ref       = read_bundle(socket, meta.ref, meta.ref_stats);
    bucket.waveforms = read_waveform(socket, meta.waveform);
    
end

function meta = read_bucket_meta(socket)

    bytes = read(socket, 104, 'uint8');
    
    meta.data.count               = typecast(bytes(1:8), 'uint64'); 
    meta.data.nbytes.header       = typecast(bytes(9:16), 'uint64');
    meta.data.nbytes.data         = typecast(bytes(17:24), 'uint64');
    meta.data.nbytes.trajectory   = typecast(bytes(25:32), 'uint64');
    
    meta.ref.count                = typecast(bytes(33:40), 'uint64');
    meta.ref.nbytes.header        = typecast(bytes(41:48), 'uint64');
    meta.ref.nbytes.data          = typecast(bytes(49:56), 'uint64');
    meta.ref.nbytes.trajectory    = typecast(bytes(57:64), 'uint64');
    
    meta.data_stats.nbytes        = typecast(bytes(65:72), 'uint64');
    meta.ref_stats.nbytes         = typecast(bytes(73:80), 'uint64');
    
    meta.waveform.count           = typecast(bytes(81:88), 'uint64');
    meta.waveform.nbytes.header   = typecast(bytes(89:96), 'uint64');
    meta.waveform.nbytes.data     = typecast(bytes(97:104), 'uint64');
    
    meta.nbytes_total = uint32( ...
        meta.data.nbytes.header + ...
        meta.data.nbytes.data + ...
        meta.data.nbytes.trajectory + ...
        meta.data_stats.nbytes + ...
        meta.ref.nbytes.header + ...
        meta.ref.nbytes.data + ...
        meta.ref.nbytes.trajectory + ...
        meta.ref_stats.nbytes + ...
        meta.waveform.nbytes.header + ...
        meta.waveform.nbytes.data);
end

function bundle = read_bundle(socket, meta, stats)

    bundle.count = meta.count;

    bundle.header = ...
        parse_acquisition_headers( ...
            reshape( ...
                read(socket, int32(meta.nbytes.header), 'uint8'), ...
                340, ...
                [] ...
            ) ...
        );

    bundle.trajectory = ...
        typecast( ...
            read(socket, int32(meta.nbytes.trajectory), 'uint8'), ...
            'single' ...
        );                
    
    bundle.data = ...
        from_interleaved_complex( ...
            typecast( ...
                read(socket, int32(meta.nbytes.data), 'uint8'), ...
                'single' ...
            ) ...
        );        
    
    bundle.stats = ...
        gadgetron.external.data.LazyAcquisitionStats( ...
            read(socket, int32(stats.nbytes), 'uint8') ...
        );
    
    if (bundle.count == 0), return; end
    
    bundle.trajectory = reshape( ...
        bundle.trajectory, ...
        bundle.header.trajectory_dimensions(1), ...
        bundle.header.number_of_samples(1), ...
        meta.count ...
    );
    
    bundle.data = reshape( ...
        bundle.data, ...
        bundle.header.number_of_samples(1), ...
        bundle.header.active_channels(1), ...
        meta.count ...
    );
end

function waveform = read_waveform(socket, meta) 

    waveform.header = ...
            read(socket, int32(meta.nbytes.header), 'uint8') ...
        ;
    
    waveform.data = ...
        typecast( ...
            read(socket, int32(meta.nbytes.data), 'uint8'), ...
            'int32' ...
        );        
end

function cplx = from_interleaved_complex(raw)
    cplx = complex(raw(1:2:end), raw(2:2:end));
end
