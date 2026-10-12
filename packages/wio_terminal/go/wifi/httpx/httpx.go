// Package httpx holds the timeout-bounded HTTP helpers behind the wifi
// package's HttpGet/HttpPost. It is split out (no netlink/probe import) so
// it can be unit-tested on the host with a plain `go test`; the parent wifi
// package only builds under TinyGo.
package httpx

import (
	"io"
	"net/http"
	"strings"
	"time"
)

// DefaultTimeout bounds a whole request (connect, write, read).
const DefaultTimeout = 15 * time.Second

type result struct {
	body string
	ok   bool
}

// Get fetches url and returns the body, or "" on any failure or if the
// request doesn't finish within timeout.
func Get(url string, timeout time.Duration) string {
	return do(http.DefaultClient, "GET", url, "", "", timeout)
}

// Post posts body to url and returns the response body, or "" on any
// failure or if the request doesn't finish within timeout.
func Post(url, contentType, body string, timeout time.Duration) string {
	return do(http.DefaultClient, "POST", url, contentType, body, timeout)
}

// do enforces timeout twice: via http.Client.Timeout (which covers dial,
// write and read when the underlying conn honours deadlines) and via a
// wall-clock select, because the netdev-backed conns on some targets may
// ignore deadlines and block forever. If the guard fires, the stuck
// goroutine is abandoned (it is released when/if the conn eventually
// returns) so the caller is never blocked.
func do(base *http.Client, method, url, contentType, body string, timeout time.Duration) string {
	client := *base
	client.Timeout = timeout

	ch := make(chan result, 1)
	go func() {
		var rd io.Reader
		if method == "POST" {
			rd = strings.NewReader(body)
		}
		req, err := http.NewRequest(method, url, rd)
		if err != nil {
			ch <- result{}
			return
		}
		if contentType != "" {
			req.Header.Set("Content-Type", contentType)
		}
		resp, err := client.Do(req)
		if err != nil {
			ch <- result{}
			return
		}
		defer resp.Body.Close()
		data, err := io.ReadAll(resp.Body)
		if err != nil {
			ch <- result{}
			return
		}
		ch <- result{string(data), true}
	}()

	select {
	case r := <-ch:
		return r.body
	case <-time.After(timeout + time.Second):
		return ""
	}
}
