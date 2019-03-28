use futures::Poll;
use std::io;
use tokio::io::{AsyncRead, AsyncWrite};

pub struct AsyncIO<R: AsyncRead, W: AsyncWrite> {
    fin: R,
    fout: W,
}

impl<R: AsyncRead, W: AsyncWrite> io::Read for AsyncIO<R, W> {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        self.fin.read(buf)
    }
}

impl<R: AsyncRead, W: AsyncWrite> io::Write for AsyncIO<R, W> {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        self.fout.write(buf)
    }
    fn flush(&mut self) -> io::Result<()> {
        self.fout.flush()
    }
}

impl<R: AsyncRead, W: AsyncWrite> AsyncRead for AsyncIO<R, W> {}
impl<R: AsyncRead, W: AsyncWrite> AsyncWrite for AsyncIO<R, W> {
    fn shutdown(&mut self) -> Poll<(), io::Error> {
        self.fout.shutdown()
    }
}

pub fn stdio() -> AsyncIO<impl AsyncRead, impl AsyncWrite> {
    let fin = tokio_file_unix::File::new_nb(tokio_file_unix::raw_stdin().unwrap())
        .unwrap()
        .into_reader(&tokio::reactor::Handle::default())
        .unwrap();
    let fout = tokio::io::stdout();
    AsyncIO { fin, fout }
}
