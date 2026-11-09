package main

import (
	"fmt"
	"io"
	"os"
)

type progress struct {
	total int64
	done  int64
	last  int
}

var copied = progress{last: -1}

func (p *progress) add(n int64) {
	p.done += n
	if p.total <= 0 {
		return
	}
	pct := int(p.done * 100 / p.total)
	if pct > 100 {
		pct = 100
	}
	if pct != p.last {
		p.last = pct
		fmt.Printf("progress %d\n", pct)
	}
}

func copyData(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o644)
	if err != nil {
		return err
	}
	buf := make([]byte, 4<<20)
	for {
		n, rerr := in.Read(buf)
		if n > 0 {
			if _, werr := out.Write(buf[:n]); werr != nil {
				out.Close()
				return fmt.Errorf("write %s: %w", dst, werr)
			}
			copied.add(int64(n))
		}
		if rerr == io.EOF {
			break
		}
		if rerr != nil {
			out.Close()
			return fmt.Errorf("read %s: %w", src, rerr)
		}
	}
	if err := out.Sync(); err != nil {
		out.Close()
		return fmt.Errorf("write %s: %w", dst, err)
	}
	return out.Close()
}
