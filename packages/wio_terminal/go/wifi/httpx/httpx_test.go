package httpx

import (
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestGetOK(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, `{"status":"ok"}`)
	}))
	defer srv.Close()
	if got := Get(srv.URL, time.Second); got != `{"status":"ok"}` {
		t.Fatalf("got %q", got)
	}
}

func TestPostOK(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(r.Body)
		io.WriteString(w, r.Header.Get("Content-Type")+"|"+string(b))
	}))
	defer srv.Close()
	if got := Post(srv.URL, "text/plain", "hi", time.Second); got != "text/plain|hi" {
		t.Fatalf("got %q", got)
	}
}

func TestGetTimesOutOnStalledServer(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(2 * time.Second)
	}))
	defer srv.Close()
	start := time.Now()
	if got := Get(srv.URL, 200*time.Millisecond); got != "" {
		t.Fatalf("got %q, want empty", got)
	}
	if d := time.Since(start); d > 1500*time.Millisecond {
		t.Fatalf("took %v", d)
	}
}

// A listener that accepts but never replies: the connection hangs after
// the TCP handshake, like the reported behaviour.
func TestGetTimesOutOnSilentListener(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	start := time.Now()
	if got := Get("http://"+ln.Addr().String(), 200*time.Millisecond); got != "" {
		t.Fatalf("got %q, want empty", got)
	}
	if d := time.Since(start); d > 1500*time.Millisecond {
		t.Fatalf("took %v", d)
	}
}

// Even if the transport ignores deadlines entirely, the wall-clock guard
// must return.
type stuckTransport struct{ release chan struct{} }

func (s stuckTransport) RoundTrip(*http.Request) (*http.Response, error) {
	<-s.release
	return nil, io.EOF
}

func TestGuardFiresWhenTransportIgnoresDeadlines(t *testing.T) {
	st := stuckTransport{release: make(chan struct{})}
	defer close(st.release)
	start := time.Now()
	got := do(&http.Client{Transport: st}, "GET", "http://x/", "", "", 200*time.Millisecond)
	if got != "" {
		t.Fatalf("got %q", got)
	}
	if d := time.Since(start); d > 1500*time.Millisecond {
		t.Fatalf("took %v", d)
	}
}

func TestBadURLReturnsEmpty(t *testing.T) {
	if got := Get("://bad", time.Second); got != "" {
		t.Fatalf("got %q", got)
	}
}
