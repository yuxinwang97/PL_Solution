import java.util.concurrent.atomic.AtomicLongArray;
class AcmeSafeState implements State {
    private AtomicLongArray value;
    
    AcmeSafeState(int length) { value = new AtomicLongArray(length);}

    public int size() { return value.length(); }

    public long[] current() 
    { 
    	long[] copy = new long[value.length()];
    	for(int i = 0; i < value.length(); i++)
    	{
    		copy[i] = (long)value.get(i);
    	}
    	return copy;
    }

    public void swap(int i, int j) 
    {	
		value.getAndIncrement(j);
		value.getAndDecrement(i);
    }
}