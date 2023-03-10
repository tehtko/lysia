pub use self::area_frame_allocator::AreaFrameAllocator;

mod area_frame_allocator;

pub const PAGE_SIZE: usize = 4096;

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct Frame 
{
    frame_number: usize,
}

impl Frame {
    fn containing_address(address: usize) -> Frame 
    {
        Frame{ frame_number: address / PAGE_SIZE }
    }
}

pub trait FrameAllocator 
{
    fn allocate_frame(&mut self) -> Option<Frame>;
    fn deallocate_frame(&mut self, frame: Frame);
}