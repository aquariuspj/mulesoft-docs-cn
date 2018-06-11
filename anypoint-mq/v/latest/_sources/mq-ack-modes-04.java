package ackmodes;

import java.util.Random;

import org.mule.api.MuleEventContext;
import org.mule.api.lifecycle.Callable;

public class RandomError implements Callable {

	@Override
	public Object onCall(MuleEventContext eventContext) throws Exception {
		int randomInt = new Random().nextInt(100);
		if (randomInt > 66) {
			throw new IllegalStateException("This should be retried");
		} else if (randomInt > 33) {
			throw new UnsupportedOperationException("This should not be retried");
		} else {
			return eventContext;
		}
	}
}
